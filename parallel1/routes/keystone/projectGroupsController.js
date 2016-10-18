(function() {
  'use strict';
  var ProjectGroupsController, async, controllerBase, openclient, redis, roleController, storage,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  roleController = require('./rolesController');

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;

  openclient = require('openclient');

  async = require('async');

  ProjectGroupsController = (function(_super) {
    __extends(ProjectGroupsController, _super);

    function ProjectGroupsController() {
      var options;
      options = {
        service: 'identity',
        profile: 'project_groups',
        baseUrl: global.cloudAPIs.keystone.v3
      };
      ProjectGroupsController.__super__.constructor.call(this, options);
      this.redisClient = redis.connect({
        'redis_host': redisConf.host,
        'redis_password': redisConf.pass,
        'redis_port': redisConf.port
      });
    }

    ProjectGroupsController.prototype.config = function(app) {
      var create, del, index, obj;
      obj = this;
      create = this.create;
      del = this.del;
      index = this.index;
      this.debug = 'production' !== app.get('env');
      app.get("/:projectId/" + this.profile, function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return index(req, res, obj);
      });
      app.post("/:projectId/" + this.profile + "/:groupId", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return create(req, res, obj);
      });
      app.del("/:projectId/" + this.profile + "/:groupId", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return del(req, res, obj);
      });
      this.storage = new storage.Storage({
        redis_client: this.redisClient,
        debug: this.debug
      });
      return ProjectGroupsController.__super__.config.call(this, app);
    };

    ProjectGroupsController.getClient = function(req, obj, token, tenant_id) {
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

    ProjectGroupsController.syncRedis = function(req, obj, client, callback) {
      var err;
      try {
        return client['groups'].all({
          endpoint_type: 'identity',
          success: function(allGroups) {
            async.parallel([
              function(cb) {
                client['group_project_memberships'].all({
                  endpoint_type: 'identity',
                  data: {
                    group: req.params.groupId
                  },
                  success: function(projects) {
                    return cb(null, projects);
                  },
                  error: function(error) {
                    return cb(error, null);
                  }
                });
              }, function(cb) {
                var groups;
                groups = [];
                async.each(allGroups, function(grp, internalCallback) {
                  client['project_group_memberships'].all({
                    endpoint_type: 'identity',
                    data: {
                      project: req.params.projectId,
                      group: grp.id
                    },
                    success: function(memberships) {
                      var mem, _i, _len;
                      for (_i = 0, _len = memberships.length; _i < _len; _i++) {
                        mem = memberships[_i];
                        groups.push({
                          id: mem.id
                        });
                      }
                      return internalCallback();
                    },
                    error: function(error) {
                      return internalCallback(error, null);
                    }
                  });
                }, function(err) {
                  return cb(err, groups);
                });
              }
            ], function(err, results) {
              var groupOpts, group_project_relation, projectOpts, project_group_relation;
              group_project_relation = [
                {
                  id: req.params.groupId,
                  group_projects: results[0]
                }
              ];
              projectOpts = {
                data: group_project_relation,
                fetch_at: new Date().getTime(),
                hash_prefix: 'group_projects'
              };
              project_group_relation = [
                {
                  id: req.params.projectId,
                  project_groups: results[1]
                }
              ];
              groupOpts = {
                data: project_group_relation,
                fetch_at: new Date().getTime(),
                hash_prefix: 'project_groups'
              };
              return async.series([
                function(cb) {
                  obj.storage.updateObjects(projectOpts, function(err, projects) {
                    logger.debug("Update the group_projects for redis.");
                    return cb(err, projects);
                  });
                }, function(cb) {
                  obj.storage.updateObjects(groupOpts, function(err, groups) {
                    logger.debug("Update the project_groups for redis.");
                    return cb(err, groups);
                  });
                }
              ], function(err, results) {
                if (err) {
                  return logger.error("Failed to update group_projects or project_groups memberships into redis!");
                }
              });
            });
            return callback();
          },
          error: function(error) {
            return callback(error);
          }
        });
      } catch (_error) {
        err = _error;
        logger.error("Failed to update group_projects or project_groups memberships into redis!");
        return callback(err);
      }
    };

    ProjectGroupsController.prototype.index = function(req, res, obj) {
      var client;
      client = ProjectGroupsController.getClient(req, obj, true);
      return client['groups'].all({
        endpoint_type: 'identity',
        success: function(allGroups) {
          var groups;
          groups = [];
          async.each(allGroups, function(grp, internalCallback) {
            client['project_group_memberships'].all({
              endpoint_type: 'identity',
              data: {
                project: req.params.projectId,
                group: grp.id
              },
              success: function(memberships) {
                var mem, _i, _len;
                for (_i = 0, _len = memberships.length; _i < _len; _i++) {
                  mem = memberships[_i];
                  groups.push({
                    id: mem.id,
                    name: mem.name
                  });
                }
                return internalCallback();
              },
              error: function(error) {
                return internalCallback(error, null);
              }
            });
          }, function(err) {
            if (err) {
              return res.send(err, 500);
            } else {
              return res.send(groups);
            }
          });
        },
        error: function(error) {
          return res.send(error, 500);
        }
      });
    };

    ProjectGroupsController.prototype.create = function(req, res, obj) {
      var roleClient, roleCtrl;
      roleCtrl = new roleController();
      roleClient = controllerBase.getClient(req, roleCtrl, true);
      return roleClient['roles'].all({}, function(err, roles) {
        var client, memberId, params, role, _i, _len;
        for (_i = 0, _len = roles.length; _i < _len; _i++) {
          role = roles[_i];
          if (role['name'] === 'Member') {
            memberId = role['id'];
            params = {
              data: {
                id: memberId,
                group: req.params.groupId,
                project: req.params.projectId
              }
            };
            client = ProjectGroupsController.getClient(req, obj, true);
            client['project_group_memberships'].create(params, function(err, data) {
              if (err) {
                logger.error("Failed to add group to project: ", req.params.projectId);
                return res.send(err, err.status);
              } else {
                return ProjectGroupsController.syncRedis(req, obj, client, function(err) {
                  if (err) {
                    return res.send(err, 500);
                  } else {
                    return res.send(data);
                  }
                });
              }
            });
            return;
          }
        }
      });
    };

    ProjectGroupsController.prototype.del = function(req, res, obj) {
      var client, params;
      params = {
        id: req.params.groupId,
        data: {
          project: req.params.projectId
        }
      };
      client = ProjectGroupsController.getClient(req, obj);
      client['project_group_memberships'].del(params, function(err, data) {
        if (err) {
          logger.error("Failed to remove group from project: ", req.params.projectId);
          return res.send(err, err.status);
        } else {
          return ProjectGroupsController.syncRedis(req, obj, client, function() {
            return res.send(data);
          });
        }
      });
    };

    return ProjectGroupsController;

  })(controllerBase);

  module.exports = ProjectGroupsController;

}).call(this);

//# sourceMappingURL=projectGroupsController.js.map
