(function() {
  'use strict';
  var RouterController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  RouterController = (function(_super) {
    __extends(RouterController, _super);

    function RouterController() {
      var options;
      options = {
        service: 'network',
        profile: 'routers',
        alias: 'routers'
      };
      RouterController.__super__.constructor.call(this, options);
    }

    RouterController.prototype.config = function(app) {
      var addInterface, obj, removeInterface;
      obj = this;
      addInterface = this.addInterface;
      removeInterface = this.removeInterface;
      app.put("/" + this.profile + "/:id/add_router_interface", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return addInterface(req, res, obj);
      });
      app.put("/" + this.profile + "/:id/remove_router_interface", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return removeInterface(req, res, obj);
      });
      return RouterController.__super__.config.call(this, app);
    };

    RouterController.prototype.addInterface = function(req, res, obj) {
      var client, params;
      client = controllerBase.getClient(req, obj);
      params = {
        data: req.body,
        id: req.params.id
      };
      return client[obj.alias].addInterface(params, function(err, data, status) {
        if (err) {
          return res.send(err, err.status);
        } else {
          return res.send(data);
        }
      });
    };

    RouterController.prototype.removeInterface = function(req, res, obj) {
      var client, params;
      client = controllerBase.getClient(req, obj);
      params = {
        data: req.body,
        id: req.params.id
      };
      return client[obj.alias].removeInterface(params, function(err, data, status) {
        if (err) {
          return res.send(err, err.status);
        } else {
          return res.send(data);
        }
      });
    };

    return RouterController;

  })(controllerBase);

  module.exports = RouterController;

}).call(this);

//# sourceMappingURL=routerController.js.map
