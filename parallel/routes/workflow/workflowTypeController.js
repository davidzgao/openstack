(function() {
  'use strict';
  var WorkflowTypeController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * workflow type controller.
   */

  WorkflowTypeController = (function(_super) {
    __extends(WorkflowTypeController, _super);

    function WorkflowTypeController() {
      var options;
      options = {
        service: 'workflow',
        profile: 'workflow-request-types'
      };
      WorkflowTypeController.__super__.constructor.call(this, options);
    }

    return WorkflowTypeController;

  })(controllerBase);

  module.exports = WorkflowTypeController;

}).call(this);

//# sourceMappingURL=workflowTypeController.js.map
