(function() {
  'use strict';
  var ClusterController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  ClusterController = (function(_super) {
    __extends(ClusterController, _super);

    function ClusterController() {
      var options;
      options = {
        service: 'compute',
        profile: 'os-aggregates',
        alias: 'clusters'
      };
      ClusterController.__super__.constructor.call(this, options);
    }

    ClusterController.prototype.config = function(app) {
      var action, obj;
      obj = this;
      action = this.action;
      app.post("/" + this.profile + "/:id/action", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return action(req, res, obj);
      });
      return ClusterController.__super__.config.call(this, app);
    };

    ClusterController.prototype.action = function(req, res, obj) {
      var client, params;
      client = controllerBase.getClient(req, obj);
      params = {
        id: req.params.id,
        data: req.body
      };
      return client[obj.alias]['action'](params, function(err, data, status) {
        if (err) {
          return res.send(err, status);
        } else {
          return res.send(data, status);
        }
      });
    };

    return ClusterController;

  })(controllerBase);

  module.exports = ClusterController;

}).call(this);

//# sourceMappingURL=clusterController.js.map
