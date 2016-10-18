(function() {
  'use strict';
  var FloatingIPController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  FloatingIPController = (function(_super) {
    __extends(FloatingIPController, _super);

    function FloatingIPController() {
      var options;
      options = {
        service: 'network',
        profile: 'floatingips',
        alias: 'floatingips'
      };
      FloatingIPController.__super__.constructor.call(this, options);
    }

    return FloatingIPController;

  })(controllerBase);

  module.exports = FloatingIPController;

}).call(this);

//# sourceMappingURL=floatingipController.js.map
