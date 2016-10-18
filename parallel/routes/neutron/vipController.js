(function() {
  'use strict';
  var VipController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  VipController = (function(_super) {
    __extends(VipController, _super);

    function VipController() {
      var options;
      options = {
        service: 'network',
        profile: 'lb/vips',
        alias: 'vips'
      };
      VipController.__super__.constructor.call(this, options);
    }

    return VipController;

  })(controllerBase);

  module.exports = VipController;

}).call(this);

//# sourceMappingURL=vipController.js.map
