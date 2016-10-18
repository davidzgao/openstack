(function() {
  'use strict';
  var NetworkController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  NetworkController = (function(_super) {
    __extends(NetworkController, _super);

    function NetworkController() {
      var options;
      options = {
        service: 'compute',
        profile: 'os-networks',
        alias: 'os-networks'
      };
      NetworkController.__super__.constructor.call(this, options);
    }

    NetworkController.prototype.config = function(app) {
      var action, obj;
      obj = this;
      action = this.action;
      app.post("/" + this.profile + "/:id/action", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return action(req, res, obj);
      });
      return NetworkController.__super__.config.call(this, app);
    };

    NetworkController.prototype.action = function(req, res, obj) {
      var client, params;
      params = {
        id: req.params.id
      };
      client = controllerBase.getClient(req, obj);
      return client[obj.alias].disassociate(params, function(err, data) {
        if (err) {
          return res.send(err);
        } else {
          return res.send(data);
        }
      });
    };

    return NetworkController;

  })(controllerBase);

  module.exports = NetworkController;

}).call(this);

//# sourceMappingURL=networkController.js.map
