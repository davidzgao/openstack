(function() {
  'use strict';
  var QuotaClassController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * quota controller.
   */

  QuotaClassController = (function(_super) {
    __extends(QuotaClassController, _super);

    function QuotaClassController() {
      var options;
      options = {
        service: 'volume',
        profile: 'os-quota-class-sets',
        alias: 'quota_class',
        adder: "cinder"
      };
      QuotaClassController.__super__.constructor.call(this, options);
    }

    QuotaClassController.prototype.config = function(app) {
      var obj, profile, update;
      obj = this;
      QuotaClassController.__super__.config.call(this, app);
      profile = "/" + this.profile;
      if (this.adder) {
        profile = "/" + this.adder + "/" + this.profile;
      }
      update = this.updateQuota;
      return app.put("" + profile + "/:id/defaults", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return update(req, res, obj);
      });
    };

    QuotaClassController.prototype.updateQuota = function(req, res, obj) {
      var client, params;
      params = {
        data: req.body,
        id: req.params.id
      };
      client = controllerBase.getClient(req, obj);
      client[obj.alias].update(params, function(err, data) {
        if (err) {
          logger.error("Failed to update " + obj.alias + " as: ", err);
          return res.send(err, obj, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    return QuotaClassController;

  })(controllerBase);

  module.exports = QuotaClassController;

}).call(this);

//# sourceMappingURL=quotaClassController.js.map
