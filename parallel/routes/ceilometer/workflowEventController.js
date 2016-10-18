(function() {
  'use strict';
  var WorkflowEventController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require("../controller").ControllerBase;

  WorkflowEventController = (function(_super) {
    __extends(WorkflowEventController, _super);

    function WorkflowEventController() {
      var options;
      options = {
        service: 'metering',
        profile: 'workflow_events',
        alias: 'workflow_event'
      };
      WorkflowEventController.__super__.constructor.call(this, options);
    }

    WorkflowEventController.prototype.index = function(req, res, obj, detail) {
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

    return WorkflowEventController;

  })(controllerBase);

  module.exports = WorkflowEventController;

}).call(this);

//# sourceMappingURL=workflowEventController.js.map
