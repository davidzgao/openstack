(function() {
  'use strict';
  var EventController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  EventController = (function(_super) {
    __extends(EventController, _super);

    function EventController() {
      var options;
      options = {
        service: 'deployment',
        profile: 'deploy/event',
        alias: 'deployEvents'
      };
      EventController.__super__.constructor.call(this, options);
    }

    EventController.prototype.create = function(req, res, obj) {
      var client, params;
      params = {
        project: req.session.tenant.id,
        data: req.body
      };
      client = controllerBase.getClient(req, obj);
      client[obj.alias].create(params, function(err, data) {
        if (err) {
          logger.error("Failed to create " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    return EventController;

  })(controllerBase);

  module.exports = EventController;

}).call(this);

//# sourceMappingURL=eventController.js.map
