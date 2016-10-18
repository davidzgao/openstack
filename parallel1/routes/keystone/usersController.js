(function() {
  'use strict';
  var UserController, controllerBase, crypto, openclient, redis, storage,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  openclient = require('openclient');

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;

  crypto = require('crypto');

  UserController = (function(_super) {
    __extends(UserController, _super);

    function UserController() {
      var options;
      options = {
        service: 'identity',
        profile: 'users',
        baseUrl: global.cloudAPIs.keystone.v3
      };
      UserController.__super__.constructor.call(this, options);
      this.redisClient = redis.connect({
        'redis_host': redisConf.host
      });
    }

    UserController.prototype.config = function(app) {
      var listProjects, membership, obj, queryByIds, search;
      obj = this;
      search = this.search;
      listProjects = this.listProjects;
      membership = this.membership;
      app.get("/" + this.profile + "/:id/projects", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return listProjects(req, res, obj);
      });
      queryByIds = this.queryByIds;
      app.get("/" + this.profile + "/query", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return queryByIds(req, res, obj);
      });
      app.get("/" + this.profile + "/search", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return search(req, res, obj);
      });
      app.get("/" + this.profile + "/membership", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return membership(req, res, obj);
      });
      this.debug = 'production' !== app.get('env');
      this.storage = new storage.Storage({
        redis_client: this.redisClient,
        debug: this.debug
      });
      return UserController.__super__.config.call(this, app);
    };

    UserController.getClient = function(req, obj, token, tenant_id) {
      var baseUrl, service, version;
      baseUrl = obj.baseUrl;
      version = global.cloudAPIs.version[obj.service];
      service = openclient.getAPI("openstack", obj.service, version);
      if (req.session.tenant && req.session.token) {
        obj.client = new service({
          url: baseUrl,
          scoped_token: req.session.token,
          tenant: req.session.tenant.id,
          debug: obj.debug
        });
      } else {
        obj.client = new service({
          url: baseUrl,
          scoped_token: token,
          tenant: tenant_id,
          debug: true
        });
      }
      return obj.client;
    };

    UserController.prototype.queryByIds = function(req, res, obj) {
      var err, options;
      try {
        options = {
          'ids': JSON.parse(req.query.ids),
          'fields': JSON.parse(req.query.fields),
          'resource_type': 'users'
        };
      } catch (_error) {
        err = _error;
        res.send(err, controllerBase._ERROR_400);
        return;
      }
      return obj.storage.getObjectsByIds(options, function(err, replies) {
        if (err) {
          res.send(err("Failed to get users."));
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(replies);
        }
      });
    };

    UserController.prototype.index = function(req, res, obj, detail) {
      var limit, limitFrom, limitTo;
      if (detail == null) {
        detail = false;
      }
      limitFrom = req.query.limit_from;
      limitTo = req.query.limit_to;
      limit = void 0;
      if (limitFrom && limitTo) {
        limit = {
          from: Number(limitFrom),
          to: Number(limitTo)
        };
      }
      delete req.query.limit_from;
      delete req.query.limit_to;
      delete req.query._;
      delete req.query._cache;
      return obj.storage.getObjects({
        resource_type: 'users',
        query: req.query,
        limit: limit,
        debug: obj.debug
      }, function(err, users) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(users);
        }
      });
    };

    UserController.prototype.show = function(req, res, obj) {
      return obj.storage.getObject({
        resource_type: 'users',
        id: req.params.id
      }, function(err, user) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(user);
        }
      });
    };

    UserController.prototype.create = function(req, res, obj) {
      var client, params;
      params = {
        data: req.body
      };
      client = UserController.getClient(req, obj);
      client[obj.alias].create(params, function(err, data) {
        var opts;
        if (err) {
          logger.error("Failed to create user: ", err);
          return res.send(err, err.status);
        } else {
          try {
            opts = {
              hash_prefix: 'users',
              data: data
            };
            return obj.storage.updateObject(opts, function(user) {
              logger.debug("Update the users from redis.");
              return res.send(data);
            });
          } catch (_error) {
            return res.send(data);
          }
        }
      });
    };

    UserController.prototype.del = function(req, res, obj) {
      var client, params;
      params = {
        id: req.params.id
      };
      client = UserController.getClient(req, obj);
      client[obj.alias].del(params, function(err, data) {
        var opts;
        if (err) {
          logger.error("Failed to delete " + obj.alias + " as: ", err);
          return res.send(err, err.status);
        } else {
          opts = {
            hash_prefix: 'users',
            object_id: req.params.id
          };
          obj.storage.deleteObject(opts, function(user) {
            return logger.debug("Delete the user from redis.");
          });
          return res.send(data);
        }
      });
    };

    UserController.prototype.update_password = function(options) {
      var client, params;
      client = UserController.getClient(options.req, options.obj, options.token, options.tenant_id);
      params = {
        data: {
          user: {
            password: options.req.body.password
          }
        },
        id: options.req.body.userId
      };
      return client['users'].update_password(params, function(err, data) {
        if (options.callback) {
          return options.callback(options.res, err, data);
        }
      });
    };

    UserController.prototype.update = function(req, res, obj) {
      var client, currentPass, currentPassword, params, sha1Hash;
      params = {
        data: {
          user: req.body
        },
        id: req.params.id
      };
      client = UserController.getClient(req, obj);
      if (req.body.new_password && req.body.old_password) {
        params = {
          data: {
            user: {
              password: req.body.new_password
            }
          },
          id: req.params.id
        };
        sha1Hash = crypto.createHash("sha1");
        currentPass = req.body.old_password;
        currentPassword = sha1Hash.update(currentPass).digest('hex');
        if (req.session.password !== currentPassword) {
          res.send("Current password error", 400);
          return;
        }
        client[obj.alias].update_password(params, function(err, data) {
          if (err) {
            logger.error("Failed ot update password!");
            return res.send(err, err.status);
          } else {
            return res.send(data);
          }
        });
      } else {
        return client[obj.alias].update_user(params, function(err, data) {
          var opts, user;
          if (err) {
            logger.error("Failed ot update user info.");
            res.send(err, err.status);
          } else {
            user = data.user;
            user.tenantId = user.default_project_id;
            delete user.default_project_id;
            opts = {
              hash_prefix: 'users',
              data: user
            };
            obj.storage.updateObject(opts, function(user) {
              res.send(data);
              return logger.debug("Success to update user detail!");
            });
          }
        });
      }
    };

    UserController.prototype.listProjects = function(req, res, obj) {
      var client, params;
      params = {
        id: req.params.id
      };
      client = UserController.getClient(req, obj);
      return client[obj.alias].listProjects(params, function(err, data) {
        if (err) {
          logger.error("Failed to get projects of user belongs.");
          return res.send(err, err.status);
        } else {
          return res.send(data);
        }
      });
    };

    UserController.prototype.membership = function(req, res, obj) {
      return obj.storage.getObjects({
        resource_type: 'projects_user_belongs_to'
      }, function(err, data) {
        if (err) {
          logger.error("Failed to get projects of user belongs.");
          return res.send(err, err.status);
        } else {
          return res.send(data);
        }
      });
    };

    UserController.prototype.search = function(req, res, obj) {
      var limit, limitFrom, limitTo, query_cons;
      limitFrom = req.query.limit_from;
      limitTo = req.query.limit_to;
      limit = void 0;
      if (limitFrom && limitTo) {
        limit = {
          from: Number(limitFrom),
          to: Number(limitTo)
        };
      }
      delete req.query.limit_from;
      delete req.query.limit_to;
      delete req.query._;
      delete req.query._cache;
      query_cons = {};
      if (req.query.searchKey && req.query.searchValue) {
        query_cons[req.query.searchKey] = [req.query.searchValue];
      }
      if (req.query.tenantId) {
        query_cons['tenant_id'] = req.query.tenantId;
      }
      return obj.storage.getObjectsByKeyValues({
        resource_type: 'users',
        query_cons: query_cons,
        require_detail: req.query.require_detail,
        condition_relation: 'and',
        debug: obj.debug
      }, function(err, users) {
        if (err) {
          logger.error("Failed to get users as: ", err);
          return res.send(err, err.status);
        } else {
          return res.send(users);
        }
      });
    };

    return UserController;

  })(controllerBase);

  module.exports = UserController;

}).call(this);

//# sourceMappingURL=usersController.js.map
