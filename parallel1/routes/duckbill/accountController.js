(function() {
  'use strict';
  var AccountController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  AccountController = (function(_super) {
    __extends(AccountController, _super);

    function AccountController() {
      var options;
      options = {
        service: 'pubcloud',
        profile: 'accounts',
        adder: 'pubcloud'
      };
      AccountController.__super__.constructor.call(this, options);
    }

    return AccountController;

  })(controllerBase);

  module.exports = AccountController;

}).call(this);

//# sourceMappingURL=accountController.js.map
