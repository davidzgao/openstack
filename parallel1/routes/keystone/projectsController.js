(function() {
  'use strict';
  var ProjectController, controllerBase, redis, storage,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;


  /*
   * The V2 API for keystone projects(tenants).
   * For hidden the confusion for project and tenant,
   * replace the tenants of projects and the projectV3
   * stand for V3 projects API.
   */

  ProjectController = (function(_super) {
    __extends(ProjectController, _super);

    function ProjectController() {
      var options;
      options = {
        service: 'identity',
        profile: 'projects'
      };
      ProjectController.__super__.constructor.call(this, options);
      this.redisClient = redis.connect({
        'redis_host': redisConf.host
      });
    }

    ProjectController.prototype.config = function(app) {
      var obj, queryByIds;
      obj = this;
      this.debug = 'production' !== app.get('env');
      this.storage = new storage.Storage({
        redis_client: this.redisClient,
        debug: this.debug
      });
      queryByIds = this.queryByIds;
      app.get("/" + this.profile + "/query", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return queryByIds(req, res, obj);
      });
      return ProjectController.__super__.config.call(this, app);
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
        query: req.query,
        limit: limit,
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
      return obj.storage.getObject({
        resource_type: 'projects',
        id: req.params.id
      }, function(err, project) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(project);
        }
      });
    };

    return ProjectController;

  })(controllerBase);

  module.exports = ProjectController;

}).call(this);

//# sourceMappingURL=projectsController.js.map
