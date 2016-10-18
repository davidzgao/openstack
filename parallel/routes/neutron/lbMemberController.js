(function() {
  'use strict';
  var MemberController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  MemberController = (function(_super) {
    __extends(MemberController, _super);

    function MemberController() {
      var options;
      options = {
        service: 'network',
        profile: 'lb/members',
        alias: 'members'
      };
      MemberController.__super__.constructor.call(this, options);
    }

    return MemberController;

  })(controllerBase);

  module.exports = MemberController;

}).call(this);

//# sourceMappingURL=lbMemberController.js.map
