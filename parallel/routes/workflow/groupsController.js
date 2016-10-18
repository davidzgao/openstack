(function() {
  'use strict';
  var GroupController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * feedback controller.
   */

  GroupController = (function(_super) {
    __extends(GroupController, _super);

    function GroupController() {
      var options;
      options = {
        service: 'workflow',
        profile: 'option_groups'
      };
      GroupController.__super__.constructor.call(this, options);
    }

    return GroupController;

  })(controllerBase);

  module.exports = GroupController;

}).call(this);

//# sourceMappingURL=groupsController.js.map
