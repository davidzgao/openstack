(function() {
  'use strict';
  var NotificationController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  NotificationController = (function(_super) {
    __extends(NotificationController, _super);

    function NotificationController() {
      var options;
      options = {
        service: 'keeper',
        profile: 'messages'
      };
      NotificationController.__super__.constructor.call(this, options);
    }

    NotificationController.prototype.config = function(app) {
      var obj, updateRead;
      obj = this;
      updateRead = this.updateRead;
      app.put("/" + this.profile + "/update/all", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return updateRead(req, res, obj);
      });
      return NotificationController.__super__.config.call(this, app);
    };

    NotificationController.prototype.updateRead = function(req, res, obj) {
      var client, params;
      params = {
        data: req.body
      };
      client = controllerBase.getClient(req, obj);
      client[obj.alias]['update_read'](params, function(err, data) {
        if (err) {
          logger.error("Failed to update " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    return NotificationController;

  })(controllerBase);

  module.exports = NotificationController;

}).call(this);

//# sourceMappingURL=notificationController.js.map
