(function() {
  'use strict';
  var ProjectController, controllerBase, openclient, redis, storage,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;

  openclient = require('openclient');

  ProjectController = (function(_super) {
    __extends(ProjectController, _super);

    function ProjectController() {
      var options;
      options = {
        service: 'identity',
        profile: 'projectsV3',
        baseUrl: global.cloudAPIs.keystone.v3
      };
      ProjectController.__super__.constructor.call(this, options);
      this.redisClient = redis.connect({
        'redis_host': redisConf.host
      });
    }

    ProjectController.prototype.config = function(app) {
      var obj, queryByIds, search, show;
      obj = this;
      this.debug = 'production' !== app.get('env');
      this.storage = new storage.Storage({
        redis_client: this.redisClient,
        debug: this.debug
      });
      show = this.show;
      search = this.search;
      app.get("" + this.profile + "/:id", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return show(req, res, obj);
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
      return ProjectController.__super__.config.call(this, app);
    };

    ProjectController.getClient = function(req, obj) {
      var baseUrl, service, version;
      baseUrl = obj.baseUrl;
      version = global.cloudAPIs.version['project'];
      service = openclient.getAPI("openstack", obj.service, version);
      obj.client = new service({
        url: baseUrl,
        scoped_token: req.session.token,
        tenant: req.session.tenant.id,
        debug: obj.debug
      });
      return obj.client;
    };

    ProjectController.prototype.queryByIds = function(req, res, obj) {
      var err, options;
      try {
        options = {
          'ids': JSON.parse(req.query.ids),
          'fields': JSON.parse(req.query.fields),
          'resource_type': 'projects'
        };
      } catch (_error) {
        err = _error;
        res.send(err, controllerBase._ERROR_400);
        return;
      }
      return obj.storage.getObjectsByIds(options, function(err, replies) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(replies);
        }
      });
    };

    ProjectController.prototype.index = function(req, res, obj, detail) {
      var limit, limitFrom, limitTo;
      if (detail == null) {
        detail = false;
      }
      if (!controllerBase.checkToken(req, res)) {
        return;
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
        resource_type: 'projects',
        sort_field: 'fetch_at',
        limit: limit,
        query: req.query,
        debug: obj.debug
      }, function(err, projects) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(projects);
        }
      });
    };

    ProjectController.prototype.show = function(req, res, obj) {
      if (!controllerBase.checkToken(req, res)) {
        return;
      }
      return obj.storage.getObject({
        resource_type: 'projects',
        id: req.params.id,
        debug: obj.debug
      }, function(err, project) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(project);
        }
      });
    };

    ProjectController.prototype.create = function(req, res, obj) {
      var client, params;
      if (!controllerBase.checkToken(req, res)) {
        return;
      }
      params = {
        data: req.body
      };
      client = ProjectController.getClient(req, obj);
      client['projects'].create(params, function(err, data, status) {
        var error, opts;
        if (err) {
          logger.error(err.message, err.status);
          return res.send(err, err.status);
        } else {
          try {
            opts = {
              hash_prefix: 'projects',
              data: data
            };
            return obj.storage.updateObject(opts, function(project) {
              return res.send(data);
            });
          } catch (_error) {
            error = _error;
            logger.error("Error at update project", error);
            return res.send(data);
          }
        }
      });
    };

    ProjectController.prototype.del = function(req, res, obj) {
      var client, params;
      if (!controllerBase.checkToken(req, res)) {
        return;
      }
      params = {
        id: req.params.id
      };
      client = ProjectController.getClient(req, obj);
      client['projects'].del(params, function(err, data) {
        var opts;
        if (err) {
          logger.error("Failed to delete " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          opts = {
            hash_prefix: 'projects',
            object_id: req.params.id
          };
          return obj.storage.deleteObject(opts, function(project) {
            return res.send(data, 200);
          });
        }
      });
    };

    ProjectController.prototype.update = function(req, res, obj) {
      var client, params;
      if (!controllerBase.checkToken(req, res)) {
        return;
      }
      params = {
        data: req.body,
        id: req.params.id
      };
      client = ProjectController.getClient(req, obj);
      client['projects'].update(params, function(err, data) {
        var args;
        if (err) {
          logger.error("Failed to update project as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          args = {
            id: req.params.id
          };
          return client['projects'].get(args, function(err, detail) {
            var opts;
            if (err) {
              return res.send(data);
            } else {
              delete detail.links;
              delete detail.domain_id;
              opts = {
                hash_prefix: 'projects',
                data: detail
              };
              return obj.storage.updateObject(opts, function(project) {
                return res.send(detail);
              });
            }
          });
        }
      });
    };

    ProjectController.prototype.search = function(req, res, obj) {
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
      if (req.query.tenant_id) {
        query_cons['tenant_id'] = req.query.tenant_id;
      }
      return obj.storage.getObjectsByKeyValues({
        resource_type: 'projects',
        query_cons: query_cons,
        require_detail: req.query.require_detail,
        condition_relation: 'and',
        limit: limit,
        debug: obj.debug
      }, function(err, projects) {
        if (err) {
          logger.error("Failed to get projects as: ", err);
          return res.send(err, err.status);
        } else {
          return res.send(projects);
        }
      });
    };

    return ProjectController;

  })(controllerBase);

  module.exports = ProjectController;

}).call(this);

//# sourceMappingURL=projectsV3Controller.js.map
