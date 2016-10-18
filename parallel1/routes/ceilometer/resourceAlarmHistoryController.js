(function() {
  'use strict';
  var ResourceAlarmHistoryController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  ResourceAlarmHistoryController = (function(_super) {
    __extends(ResourceAlarmHistoryController, _super);

    function ResourceAlarmHistoryController() {
      var options;
      options = {
        service: 'metering',
        profile: 'resource_alarm_history',
        alias: 'resource_alarm_history'
      };
      ResourceAlarmHistoryController.__super__.constructor.call(this, options);
    }

    ResourceAlarmHistoryController.prototype.index = function(req, res, obj, detail) {
      var client, params, query;
      if (detail == null) {
        detail = false;
      }
      params = {
        query: {}
      };
      for (query in req.query) {
        if (query === '_' || query === '_cache') {
          continue;
        }
        params.query[query] = req.query[query];
      }
      if (detail) {
        params["detail"] = detail;
      }
      client = controllerBase.getClient(req, obj);
      client[obj.alias].all(params, function(err, data) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          data.localeTime = (new Date()).getTime();
          return res.send(data);
        }
      });
    };

    return ResourceAlarmHistoryController;

  })(controllerBase);

  module.exports = ResourceAlarmHistoryController;

}).call(this);

//# sourceMappingURL=resourceAlarmHistoryController.js.map
