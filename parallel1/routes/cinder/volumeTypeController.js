(function() {
  'use strict';
  var VolumeTypeController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  VolumeTypeController = (function(_super) {
    __extends(VolumeTypeController, _super);

    function VolumeTypeController() {
      var options;
      options = {
        service: 'volume',
        profile: 'volume_types',
        alias: 'types'
      };
      VolumeTypeController.__super__.constructor.call(this, options);
    }

    return VolumeTypeController;

  })(controllerBase);

  module.exports = VolumeTypeController;

}).call(this);

//# sourceMappingURL=volumeTypeController.js.map
