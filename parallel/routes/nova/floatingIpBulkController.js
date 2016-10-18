(function() {
  'use strict';
  var FloatingIpBulkController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  FloatingIpBulkController = (function(_super) {
    __extends(FloatingIpBulkController, _super);

    function FloatingIpBulkController() {
      var options;
      options = {
        service: 'compute',
        profile: 'os-floating-ips-bulk',
        alias: 'floating_ip_info'
      };
      FloatingIpBulkController.__super__.constructor.call(this, options);
    }

    return FloatingIpBulkController;

  })(controllerBase);

  module.exports = FloatingIpBulkController;

}).call(this);

//# sourceMappingURL=floatingIpBulkController.js.map
