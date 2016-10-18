(function() {
  'use strict';
  var SubnetController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  SubnetController = (function(_super) {
    __extends(SubnetController, _super);

    function SubnetController() {
      var options;
      options = {
        service: 'network',
        profile: 'subnets',
        alias: 'subnets'
      };
      SubnetController.__super__.constructor.call(this, options);
    }

    return SubnetController;

  })(controllerBase);

  module.exports = SubnetController;

}).call(this);

//# sourceMappingURL=subnetController.js.map
