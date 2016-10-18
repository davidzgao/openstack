(function() {
  'use strict';
  var GroupUsersController, async, controllerBase, openclient, redis, storage,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;

  openclient = require('openclient');

  async = require('async');

  GroupUsersController = (function(_super) {
    __extends(GroupUsersController, _super);

    function GroupUsersController() {
      var options;
      options = {
        service: 'identity',
        profile: 'group_users',
        baseUrl: global.cloudAPIs.keystone.v3
      };
      GroupUsersController.__super__.constructor.call(this, options);
      this.redisClient = redis.connect({
        'redis_host': redisConf.host,
        'redis_password': redisConf.pass,
        'redis_port': redisConf.port
      });
    }

    GroupUsersController.prototype.config = function(app) {
      var create, del, index, obj;
      obj = this;
      create = this.create;
      del = this.del;
      index = this.index;
      this.debug = 'production' !== app.get('env');
      app.get("/:groupId/" + this.profile, function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return index(req, res, obj);
      });
      app.post("/:groupId/" + this.profile + "/:userId", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return create(req, res, obj);
      });
      app.del("/:groupId/" + this.profile + "/:userId", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return del(req, res, obj);
      });
      this.storage = new storage.Storage({
        redis_client: this.redisClient,
        debug: this.debug
      });
      return GroupUsersController.__super__.config.call(this, app);
    };

    GroupUsersController.getClient = function(req, obj, token, tenant_id) {
      var baseUrl, service, version;
      baseUrl = obj.baseUrl;
      version = global.cloudAPIs.version[obj.service];
      service = openclient.getAPI("openstack", obj.service, "3.0");
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

    GroupUsersController.syncRedis = function(req, obj, client, callback) {
      try {
        async.parallel([
          function(cb) {
            client['group_users'].all({
              endpoint_type: 'identity',
              data: {
                group: req.params.groupId
              },
              success: function(users) {
                return cb(null, users);
              },
              error: function(error) {
                return cb(error, null);
              }
            });
          }, function(cb) {
            client['user_groups'].all({
              endpoint_type: 'identity',
              data: {
                user: req.params.userId
              },
              success: function(groups) {
                return cb(null, groups);
              },
              error: function(error) {
                return cb(error, null);
              }
            });
          }
        ], function(err, results) {
          var groupOpts, group_users_relation, userOpts, user_groups_relation;
          group_users_relation = [
            {
              id: req.params.groupId,
              users: results[0]
            }
          ];
          userOpts = {
            data: group_users_relation,
            fetch_at: new Date().getTime(),
            hash_prefix: 'group_users'
          };
          user_groups_relation = [
            {
              id: req.params.userId,
              groups: results[1]
            }
          ];
          groupOpts = {
            data: user_groups_relation,
            fetch_at: new Date().getTime(),
            hash_prefix: 'user_groups'
          };
          return async.series([
            function(cb) {
              obj.storage.updateObjects(userOpts, function(err, groupUsers) {
                logger.debug("Update the group_users for redis.");
                return cb(err, groupUsers);
              });
            }, function(cb) {
              obj.storage.updateObjects(groupOpts, function(err, groupUsers) {
                logger.debug("Update the user_groups for redis.");
                return cb(err, groupUsers);
              });
            }
          ], function(err) {
            return logger.error("Failed to update group_users or user_groups memberships into redis!");
          });
        });
        return callback();
      } catch (_error) {
        return callback();
      }
    };

    GroupUsersController.prototype.index = function(req, res, obj) {
      var client, params;
      params = {
        data: {
          group: req.params.groupId
        }
      };
      client = GroupUsersController.getClient(req, obj, true);
      return client['group_users'].all(params, function(err, data) {
        if (err) {
          logger.error("Failed to get users for group: ", req.params.groupId);
          return res.send(err, err.status);
        } else {
          return res.send(data);
        }
      });
    };

    GroupUsersController.prototype.create = function(req, res, obj) {
      var client, params;
      params = {
        data: {
          group: req.params.groupId,
          user: req.params.userId
        }
      };
      client = GroupUsersController.getClient(req, obj, true);
      client['group_users'].create(params, function(err, data) {
        if (err) {
          logger.error("Failed to add user for group: ", req.params.groupId);
          return res.send(err, obj._ERROR_400);
        } else {
          return GroupUsersController.syncRedis(req, obj, client, function() {
            return res.send(data);
          });
        }
      });
    };

    GroupUsersController.prototype.del = function(req, res, obj) {
      var client, params;
      params = {
        endpoint_type: 'identity',
        data: {
          group: req.params.groupId,
          user: req.params.userId
        }
      };
      client = GroupUsersController.getClient(req, obj, true);
      client[obj.profile].del(params, function(err, data) {
        if (err) {
          logger.error("Failed to remove user for group: ", req.params.groupId);
          return res.send(err, err.status);
        } else {
          return GroupUsersController.syncRedis(req, obj, client, function() {
            return res.send(data);
          });
        }
      });
    };

    return GroupUsersController;

  })(controllerBase);

  module.exports = GroupUsersController;

}).call(this);

//# sourceMappingURL=groupUsersController.js.map
