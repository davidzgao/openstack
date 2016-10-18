(function() {
  'use strict';
  var NodeController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  NodeController = (function(_super) {
    __extends(NodeController, _super);

    function NodeController() {
      var options;
      options = {
        service: 'deployment',
        profile: 'deploy/node',
        alias: 'deployNodes'
      };
      NodeController.__super__.constructor.call(this, options);
    }

    return NodeController;

  })(controllerBase);

  module.exports = NodeController;

}).call(this);

//# sourceMappingURL=nodeController.js.map
