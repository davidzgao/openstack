(function() {
  'use strict';
  var OptionController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * feedback controller.
   */

  OptionController = (function(_super) {
    __extends(OptionController, _super);

    function OptionController() {
      var options;
      options = {
        service: 'workflow',
        profile: 'options'
      };
      OptionController.__super__.constructor.call(this, options);
    }

    OptionController.prototype.update = function(req, res, obj) {
      var client, params;
      params = {
        data: req.body,
        id: req.params.id
      };
      client = controllerBase.getClient(req, obj);
      client[obj.alias].update(params, function(err, data) {
        var confInfo;
        if (err) {
          logger.error("Failed to update " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          confInfo = data.option;
          switch (confInfo.key) {
            case 'smtp_server':
              global.emailConf.smtp_server = confInfo.value;
              break;
            case 'email_sender':
              global.emailConf.sender = confInfo.value;
              break;
            case 'email_sender_password':
              global.emailConf.password = confInfo.value;
              break;
            case 'email_sender_name':
              global.emailConf.sender_name = confInfo.value;
              break;
            case 'site_name':
              global.emailConf.site_display_name = confInfo.value;
              break;
            default:
              break;
          }
          global.transport = void 0;
          return res.send(data);
        }
      });
    };

    return OptionController;

  })(controllerBase);

  module.exports = OptionController;

}).call(this);

//# sourceMappingURL=optionController.js.map
