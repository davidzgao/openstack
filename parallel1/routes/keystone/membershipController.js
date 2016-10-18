(function() {
  'use strict';
  var MembershipController, controllerBase, openclient, redis, storage,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;

  openclient = require('openclient');


  /*
   * The V2 API for keystone projects(tenants).
   * For hidden the confusion for project and tenant,
   * replace the tenants of projects and the projectV3
   * stand for V3 projects API.
   */

  MembershipController = (function(_super) {
    __extends(MembershipController, _super);

    function MembershipController() {
      var options;
      options = {
        service: 'identity',
        profile: 'membership'
      };
      MembershipController.__super__.constructor.call(this, options);
      this.redisClient = redis.connect({
        'redis_host': redisConf.host,
        'redis_password': redisConf.pass,
        'redis_port': redisConf.port
      });
    }

    MembershipController.prototype.config = function(app) {
      var create, del, obj;
      obj = this;
      create = this.create;
      del = this.del;
      this.debug = 'production' !== app.get('env');
      app.post("/" + this.profile + "/:id", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return create(req, res, obj);
      });
      app.del("/" + this.profile + "/:id/:user", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return del(req, res, obj);
      });
      this.storage = new storage.Storage({
        redis_client: this.redisClient,
        debug: this.debug
      });
      return MembershipController.__super__.config.call(this, app);
    };

    MembershipController.getClient = function(req, obj, token, tenant_id) {
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

    MembershipController.prototype.show = function(req, res, obj) {
      var client, params;
      params = {
        data: {
          project: req.params.id
        }
      };
      client = controllerBase.getClient(req, obj, true);
      client['membership'].all(params, function(err, data) {
        if (err) {
          logger.error("Failed to get membership of tenant:", req.params.id);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    MembershipController.prototype.create = function(req, res, obj) {
      var client, params;
      params = {
        endpoint_type: 'identity',
        data: {
          project: req.params.id,
          user: req.body.user,
          id: req.body.role
        }
      };
      client = controllerBase.getClient(req, obj, true);
      return client['membership'].create(params, function(err, data) {
        var param, v3client;
        if (err) {
          logger.error("Failed add user for project: ", req.params.id);
          return res.send(err, obj._ERROR_400);
        } else {
          param = {
            id: req.body.user
          };
          obj.baseUrl = global.cloudAPIs.keystone.v3;
          v3client = MembershipController.getClient(req, obj);
          v3client['users'].listProjects(param, function(error, projects) {
            return obj.storage.getObject({
              resource_type: 'projects_user_belongs_to',
              id: req.body.user
            }, function(err, belongs) {
              if (belongs) {
                belongs.projects = projects.projects;
                return obj.storage.updateObject({
                  hash_prefix: 'projects_user_belongs_to',
                  data: belongs,
                  fetch_at: belongs.fetch_at,
                  need_fresh: true
                }, function(err, reply) {
                  if (err) {
                    return logger.error("Error at update hash for projects_user_belongs_to");
                  }
                });
              }
            });
          });
          return res.send(data);
        }
      });
    };

    MembershipController.prototype.del = function(req, res, obj) {
      var client, params;
      params = {
        endpoint_type: 'identity',
        id: req.params.user,
        data: {
          project: req.params.id
        }
      };
      client = controllerBase.getClient(req, obj, true);
      return client['membership'].del(params, function(err, data, status) {
        if (err) {
          logger.error("Failed remove user for project: ", req.params.id);
          return res.send(err, status);
        } else {
          obj.storage.getObject({
            resource_type: 'projects_user_belongs_to',
            id: req.params.user
          }, function(err, belongs) {
            var newProjects, project, projects, _i, _len;
            if (belongs) {
              if (belongs.projects) {
                newProjects = [];
                projects = JSON.parse(belongs.projects);
                for (_i = 0, _len = projects.length; _i < _len; _i++) {
                  project = projects[_i];
                  if (project.id === req.params.id) {
                    continue;
                  } else {
                    newProjects.push(project);
                  }
                }
                belongs.projects = newProjects;
                return obj.storage.updateObject({
                  hash_prefix: 'projects_user_belongs_to',
                  data: belongs,
                  fetch_at: belongs.fetch_at,
                  need_fresh: true
                }, function(err, reply) {
                  if (err) {
                    return logger.error("Error at update hash for projects_user_belongs_to");
                  }
                });
              }
            }
          });
          logger.debug("Success remove user for project: ", req.params.id);
          return res.send(data, status.status);
        }
      });
    };

    return MembershipController;

  })(controllerBase);

  module.exports = MembershipController;

}).call(this);

//# sourceMappingURL=membershipController.js.map
