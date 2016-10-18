(function() {
  'use strict';
  var FloatingIpController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  FloatingIpController = (function(_super) {
    __extends(FloatingIpController, _super);

    function FloatingIpController() {
      var options;
      options = {
        service: 'compute',
        profile: 'os-floating-ips',
        alias: 'floating_ips'
      };
      FloatingIpController.__super__.constructor.call(this, options);
    }

    return FloatingIpController;

  })(controllerBase);

  module.exports = FloatingIpController;

}).call(this);

//# sourceMappingURL=floatingIpController.js.map
