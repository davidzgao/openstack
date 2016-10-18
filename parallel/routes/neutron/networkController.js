(function() {
  'use strict';
  var NetworkController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  NetworkController = (function(_super) {
    __extends(NetworkController, _super);

    function NetworkController() {
      var options;
      options = {
        service: 'network',
        profile: 'networks',
        alias: 'networks'
      };
      NetworkController.__super__.constructor.call(this, options);
    }

    return NetworkController;

  })(controllerBase);

  module.exports = NetworkController;

}).call(this);

//# sourceMappingURL=networkController.js.map
