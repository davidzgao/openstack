(function() {
  'use strict';
  var HealthMonitorController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  HealthMonitorController = (function(_super) {
    __extends(HealthMonitorController, _super);

    function HealthMonitorController() {
      var options;
      options = {
        service: 'network',
        profile: 'lb/health_monitors',
        alias: 'health_monitors'
      };
      HealthMonitorController.__super__.constructor.call(this, options);
    }

    return HealthMonitorController;

  })(controllerBase);

  module.exports = HealthMonitorController;

}).call(this);

//# sourceMappingURL=lbHealthMonitorController.js.map
