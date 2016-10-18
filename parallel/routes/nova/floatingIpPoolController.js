(function() {
  'use strict';
  var FloatingIpPoolController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  FloatingIpPoolController = (function(_super) {
    __extends(FloatingIpPoolController, _super);

    function FloatingIpPoolController() {
      var options;
      options = {
        service: 'compute',
        profile: 'os-floating-ip-pools',
        alias: 'floating_ip_pools'
      };
      FloatingIpPoolController.__super__.constructor.call(this, options);
    }

    return FloatingIpPoolController;

  })(controllerBase);

  module.exports = FloatingIpPoolController;

}).call(this);

//# sourceMappingURL=floatingIpPoolController.js.map
