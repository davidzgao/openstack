(function() {
  'use strict';
  var SnapshotController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * quota controller.
   */

  SnapshotController = (function(_super) {
    __extends(SnapshotController, _super);

    function SnapshotController() {
      var options;
      options = {
        service: 'volume',
        profile: 'snapshots',
        adder: "cinder"
      };
      SnapshotController.__super__.constructor.call(this, options);
    }

    return SnapshotController;

  })(controllerBase);

  module.exports = SnapshotController;

}).call(this);

//# sourceMappingURL=snapshotController.js.map
