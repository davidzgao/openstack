(function() {
  'use strict';
  var SecurityGroupRuleController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  SecurityGroupRuleController = (function(_super) {
    __extends(SecurityGroupRuleController, _super);

    function SecurityGroupRuleController() {
      var options;
      options = {
        service: 'network',
        profile: 'security-group-rules',
        alias: 'security-group-rules'
      };
      SecurityGroupRuleController.__super__.constructor.call(this, options);
    }

    return SecurityGroupRuleController;

  })(controllerBase);

  module.exports = SecurityGroupRuleController;

}).call(this);

//# sourceMappingURL=securityGroupRuleController.js.map
