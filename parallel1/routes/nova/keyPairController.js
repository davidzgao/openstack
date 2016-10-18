(function() {
  'use strict';
  var KeyPairController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  KeyPairController = (function(_super) {
    __extends(KeyPairController, _super);

    function KeyPairController() {
      var options;
      options = {
        service: 'compute',
        profile: 'os-keypairs',
        alias: 'keypairs'
      };
      KeyPairController.__super__.constructor.call(this, options);
    }

    return KeyPairController;

  })(controllerBase);

  module.exports = KeyPairController;

}).call(this);

//# sourceMappingURL=keyPairController.js.map
