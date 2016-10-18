(function() {
  'use strict';
  var TenantUsageController, async, controllerBase, redis, storage,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  async = require('async');

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;


  /**
    * server controller.
   */

  TenantUsageController = (function(_super) {
    __extends(TenantUsageController, _super);

    function TenantUsageController() {
      var options;
      options = {
        service: 'compute',
        profile: 'os-simple-tenant-usage',
        alias: 'usage'
      };
      TenantUsageController.__super__.constructor.call(this, options);
      this.redisClient = redis.connect({
        'redis_host': redisConf.host
      });
    }

    TenantUsageController.prototype.config = function(app) {
      var obj, reportAll;
      obj = this;
      reportAll = this.reportAll;
      app.get("/" + this.profile + "/download", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return reportAll(req, res, obj);
      });
      this.debug = 'production' !== app.get('env');
      this.storage = new storage.Storage({
        redis_client: this.redisClient,
        debug: this.debug
      });
      return TenantUsageController.__super__.config.call(this, app);
    };

    TenantUsageController.prototype.reportAll = function(req, res, obj) {
      var client, params, query, usageCallback, usageGet;
      params = {
        query: {}
      };
      for (query in req.query) {
        if (query === '_' || query === '_cache') {
          continue;
        }
        params.query[query] = req.query[query];
      }
      client = controllerBase.getClient(req, obj);
      usageCallback = function(results, res, err) {
        var reportNote, _;
        _ = i18n.__;
        reportNote = {
          project: _("Project Name"),
          projectId: _("Project ID"),
          cpuTotal: _("CPU Hours"),
          memUsage: _("RAM Hours(GB*Hour)"),
          diskUsage: _("Disk Hours(GB*Hour)"),
          totalUsage: _("Instances Uptime(Hour)"),
          instanceName: _("Instance Name"),
          ramGB: _("RAM (GB)"),
          diskGB: _("Disk (GB)"),
          upTime: _("Uptime (Hour)")
        };
        return obj.storage.getObjects({
          resource_type: 'projects',
          query: {},
          debug: obj.debug
        }, function(err, projects) {
          var convertGB, project, projectsMap, serverUsages, usage, _i, _j, _len, _len1, _ref;
          projectsMap = {};
          serverUsages = {};
          if (err) {
            return logger.error("Failed to get projects at generate usage report!");
          } else {
            _ref = projects.data;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              project = _ref[_i];
              projectsMap[project.id] = project.name;
            }
            for (_j = 0, _len1 = results.length; _j < _len1; _j++) {
              usage = results[_j];
              usage.project_name = projectsMap[usage.tenant_id];
              if (usage.total_vcpus_usage > 1) {
                usage.cpuUsage = usage.total_vcpus_usage.toFixed(2);
              } else {
                usage.cpuUsage = 0;
              }
              if (usage.total_memory_mb_usage > 1) {
                convertGB = usage.total_memory_mb_usage / 1024;
                usage.memUsage = convertGB.toFixed(2);
              } else {
                usage.memUsage = 0;
              }
              if (usage.total_local_gb_usage > 1) {
                usage.diskUsage = usage.total_local_gb_usage.toFixed(2);
              } else {
                usage.diskUsage = 0;
              }
              if (usage.total_hours > 1) {
                usage.totalHours = usage.total_hours.toFixed(2);
              } else {
                usage.totalHours = 0;
              }
              serverUsages[usage.tenant_id] = usage.server_usages;
            }
            return res.render('usage', {
              usage: results,
              note: reportNote,
              serverUsages: serverUsages
            });
          }
        });
      };
      usageGet = function(options, callback) {
        var projectParams;
        projectParams = {
          id: options.tenant_id,
          query: params.query
        };
        return client[obj.alias].get(projectParams, function(err, usage) {
          if (err) {
            return callback(err, []);
          } else {
            return callback(null, usage);
          }
        });
      };
      return client[obj.alias].all(params, function(err, data) {
        if (err) {
          logger.error("Failed to get tenant usage.");
          return res.send(err, obj._ERROR_400);
        } else {
          return async.map(data, usageGet, function(err, results) {
            return usageCallback(results, res, err);
          });
        }
      });
    };

    return TenantUsageController;

  })(controllerBase);

  module.exports = TenantUsageController;

}).call(this);

//# sourceMappingURL=tenantUsageController.js.map
