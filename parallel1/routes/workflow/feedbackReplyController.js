(function() {
  'use strict';
  var FeedbackReplyController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * feedback controller.
   */

  FeedbackReplyController = (function(_super) {
    __extends(FeedbackReplyController, _super);

    function FeedbackReplyController() {
      var options;
      options = {
        service: 'workflow',
        profile: 'feedback_replies'
      };
      FeedbackReplyController.__super__.constructor.call(this, options);
    }

    return FeedbackReplyController;

  })(controllerBase);

  module.exports = FeedbackReplyController;

}).call(this);

//# sourceMappingURL=feedbackReplyController.js.map
