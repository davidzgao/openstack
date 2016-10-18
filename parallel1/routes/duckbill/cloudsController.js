(function() {
  'use strict';
  var CloudsController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  CloudsController = (function(_super) {
    __extends(CloudsController, _super);

    function CloudsController() {
      var options;
      options = {
        service: 'pubcloud',
        profile: 'clouds',
        adder: 'pubcloud'
      };
      CloudsController.__super__.constructor.call(this, options);
    }

    return CloudsController;

  })(controllerBase);

  module.exports = CloudsController;

}).call(this);

//# sourceMappingURL=cloudsController.js.map
