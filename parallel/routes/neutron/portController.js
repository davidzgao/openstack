(function() {
  'use strict';
  var PortController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  PortController = (function(_super) {
    __extends(PortController, _super);

    function PortController() {
      var options;
      options = {
        service: 'network',
        profile: 'ports',
        alias: 'ports'
      };
      PortController.__super__.constructor.call(this, options);
    }

    return PortController;

  })(controllerBase);

  module.exports = PortController;

}).call(this);

//# sourceMappingURL=portController.js.map
