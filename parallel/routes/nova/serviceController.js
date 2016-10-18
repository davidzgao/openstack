(function() {
  'use strict';
  var ServiceController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  ServiceController = (function(_super) {
    __extends(ServiceController, _super);

    function ServiceController() {
      var options;
      options = {
        service: 'compute',
        profile: 'os-services',
        alias: 'services'
      };
      ServiceController.__super__.constructor.call(this, options);
    }

    ServiceController.prototype.config = function(app) {
      var action, disableService, enableService, obj;
      obj = this;
      action = this.action;
      enableService = this.enableService;
      disableService = this.disableService;
      app.put("/" + this.profile + "/enable", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return enableService(req, res, obj);
      });
      app.put("/" + this.profile + "/disable", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return disableService(req, res, obj);
      });
      return ServiceController.__super__.config.call(this, app);
    };

    ServiceController.prototype.enableService = function(req, res, obj) {
      var client, params;
      client = controllerBase.getClient(req, obj);
      params = {
        data: req.body
      };
      return client[obj.alias].enable(params, function(err, data, status) {
        if (err) {
          return res.send(err, status);
        } else {
          return res.send(data, status);
        }
      });
    };

    ServiceController.prototype.disableService = function(req, res, obj) {
      var client, params;
      client = controllerBase.getClient(req, obj);
      params = {
        data: req.body
      };
      return client[obj.alias].disable(params, function(err, data, status) {
        if (err) {
          return res.send(err, status);
        } else {
          return res.send(data, status);
        }
      });
    };

    return ServiceController;

  })(controllerBase);

  module.exports = ServiceController;

}).call(this);

//# sourceMappingURL=serviceController.js.map
