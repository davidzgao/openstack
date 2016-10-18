(function() {
  'use strict';
  var AlarmRuleController, async, controllerBase, redis, storage,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;

  async = require('async');

  AlarmRuleController = (function(_super) {
    __extends(AlarmRuleController, _super);

    function AlarmRuleController() {
      var options;
      options = {
        service: 'metering',
        profile: 'alarm_rule',
        alias: 'alarm'
      };
      AlarmRuleController.__super__.constructor.call(this, options);
    }

    AlarmRuleController.prototype.config = function(app) {
      var obj;
      obj = this;
      this.debug = 'production' !== app.get('env');
      return AlarmRuleController.__super__.config.call(this, app);
    };

    AlarmRuleController.queryRelative = function(options, callback) {
      var redisClient, storageObj;
      redisClient = redis.connect({
        'redis_host': redisConf.host,
        'redis_password': redisConf.pass,
        'redis_port': redisConf.port
      });
      storage = require('ecutils').storage;
      storageObj = new storage.Storage({
        redis_client: redisClient,
        debug: true
      });
      return storageObj.getObjectsByIds(options.params, function(err, data) {
        var resource_type;
        if (err) {
          resource_type = options.params.resource_type;
          logger.error("Failed to get " + resource_type + " as: ", err);
          return callback(err, []);
        } else {
          return callback(null, data);
        }
      });
    };

    AlarmRuleController.assembleQuery = function(rule) {
      var userIds, userOptions;
      userIds = [rule.user_id];
      userOptions = {
        params: {
          ids: userIds,
          fields: ['name'],
          resource_type: 'users'
        }
      };
      return [userOptions];
    };

    AlarmRuleController.prototype.index = function(req, res, obj) {
      var client, params, query;
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
      return client[obj.alias].all(params, function(err, rules) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(rules);
        }
      });
    };

    AlarmRuleController.prototype.show = function(req, res, obj) {
      var client, params, query;
      params = {
        id: req.params.id,
        query: {}
      };
      for (query in req.query) {
        if (query === '_' || query === '_cache') {
          continue;
        }
        params.query[query] = req.query[query];
      }
      client = controllerBase.getClient(req, obj);
      return client[obj.alias].get(params, function(err, rule) {
        var options;
        if (err) {
          logger.error("Failed to get " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          options = AlarmRuleController.assembleQuery(rule);
          return async.map(options, AlarmRuleController.queryRelative, function(err, results) {
            var userMap;
            if (err) {
              return res.send(rule);
            } else {
              userMap = results[0];
              if (userMap[rule.user_id]) {
                rule.user_name = userMap[rule.user_id].name;
              }
              return res.send(rule);
            }
          });
        }
      });
    };

    AlarmRuleController.prototype.del = function(req, res, obj) {
      var client, params;
      params = {
        id: req.params.id
      };
      params.headers = {
        'Content-Length': 0
      };
      client = controllerBase.getClient(req, obj);
      client[obj.alias].del(params, function(err, data) {
        if (err) {
          logger.error("Failed to delete " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    return AlarmRuleController;

  })(controllerBase);

  module.exports = AlarmRuleController;

}).call(this);

//# sourceMappingURL=alarm_ruleController.js.map
