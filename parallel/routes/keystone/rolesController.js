(function() {
  'use strict';
  var RoleController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /*
   * The V2 API for keystone projects(tenants).
   * For hidden the confusion for project and tenant,
   * replace the tenants of projects and the projectV3
   * stand for V3 projects API.
   */

  RoleController = (function(_super) {
    __extends(RoleController, _super);

    function RoleController() {
      var options;
      options = {
        service: 'identity',
        profile: 'roles'
      };
      RoleController.__super__.constructor.call(this, options);
    }

    RoleController.prototype.config = function(app) {
      var obj;
      obj = this;
      this.debug = 'production' !== app.get('env');
      return RoleController.__super__.config.call(this, app);
    };

    RoleController.prototype.index = function(req, res, obj, detail) {
      var client, params;
      if (detail == null) {
        detail = false;
      }
      params = {};
      client = controllerBase.getClient(req, obj, true);
      return client['roles'].all(params, function(err, data) {
        if (err) {
          logger.error("Failed to get role list");
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

//# sourceMappingURL=rolesController.js.map
