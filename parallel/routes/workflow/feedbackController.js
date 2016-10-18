(function() {
  'use strict';
  var FeedbackController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * feedback controller.
   */

  FeedbackController = (function(_super) {
    __extends(FeedbackController, _super);

    function FeedbackController() {
      var options;
      options = {
        service: 'workflow',
        profile: 'feedbacks'
      };
      FeedbackController.__super__.constructor.call(this, options);
    }

    return FeedbackController;

  })(controllerBase);

  module.exports = FeedbackController;

}).call(this);

//# sourceMappingURL=feedbackController.js.map
