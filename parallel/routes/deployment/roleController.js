(function() {
  'use strict';
  var RoleController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  RoleController = (function(_super) {
    __extends(RoleController, _super);

    function RoleController() {
      var options;
      options = {
        service: 'deployment',
        profile: 'deploy/role',
        alias: 'deployRoles'
      };
      RoleController.__super__.constructor.call(this, options);
    }

    RoleController.prototype.index = function(req, res, obj, detail) {
      var client, params, query;
      if (detail == null) {
        detail = false;
      }
      params = {
        query: {}
      };
      params.project = req.session.tenant.id;
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
          return res.send(data);
        }
      });
    };

    return RoleController;

  })(controllerBase);

  module.exports = RoleController;

}).call(this);

//# sourceMappingURL=roleController.js.map
