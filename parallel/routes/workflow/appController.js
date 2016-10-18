(function() {
  'use strict';
  var AppController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * workflow type controller.
   */

  AppController = (function(_super) {
    __extends(AppController, _super);

    function AppController() {
      var options;
      options = {
        service: 'workflow',
        profile: 'apps'
      };
      AppController.__super__.constructor.call(this, options);
    }

    AppController.prototype.config = function(app) {
      var image, obj;
      obj = this;
      image = this.image;
      app.get("/" + this.profile + "/:id/image", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return image(req, res, obj);
      });
      return AppController.__super__.config.call(this, app);
    };

    AppController.prototype.image = function(req, res, obj) {
      var client, params;
      params = {
        id: req.params.id,
        res: "/" + req.params.id + "/image"
      };
      client = controllerBase.getClient(req, obj);
      client[obj.alias].getImage(params, function(err, data) {
        if (err) {
          return logger.error("Failed to get app image.");
        } else {
          return res.send(data);
        }
      });
    };

    return AppController;

  })(controllerBase);

  module.exports = AppController;

}).call(this);

//# sourceMappingURL=appController.js.map
