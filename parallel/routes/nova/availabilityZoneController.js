(function() {
  'use strict';
  var AvailabilityZoneController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  AvailabilityZoneController = (function(_super) {
    __extends(AvailabilityZoneController, _super);

    function AvailabilityZoneController() {
      var options;
      options = {
        service: 'compute',
        profile: 'os-availability-zone',
        alias: 'availability_zones'
      };
      AvailabilityZoneController.__super__.constructor.call(this, options);
    }

    return AvailabilityZoneController;

  })(controllerBase);

  module.exports = AvailabilityZoneController;

}).call(this);

//# sourceMappingURL=availabilityZoneController.js.map
