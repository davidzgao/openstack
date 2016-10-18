(function() {
  'use strict';
  var SecurityGroupController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  SecurityGroupController = (function(_super) {
    __extends(SecurityGroupController, _super);

    function SecurityGroupController() {
      var options;
      options = {
        service: 'compute',
        profile: 'os-security-groups',
        alias: 'security_groups'
      };
      SecurityGroupController.__super__.constructor.call(this, options);
    }

    return SecurityGroupController;

  })(controllerBase);

  module.exports = SecurityGroupController;

}).call(this);

//# sourceMappingURL=securityGroupController.js.map
