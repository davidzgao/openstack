(function() {
  'use strict';
  var QuotaController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * quota controller.
   */

  QuotaController = (function(_super) {
    __extends(QuotaController, _super);

    function QuotaController() {
      var options;
      options = {
        service: 'volume',
        profile: 'os-quota-sets',
        alias: 'quotas',
        adder: "cinder"
      };
      QuotaController.__super__.constructor.call(this, options);
    }

    QuotaController.prototype.config = function(app) {
      var detail, obj, profile, updateDefault;
      obj = this;
      QuotaController.__super__.config.call(this, app);
      profile = "/" + this.profile;
      if (this.adder) {
        profile = "/" + this.adder + "/" + this.profile;
      }
      detail = this.detailQuota;
      app.get("" + profile + "/:id/defaults", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return detail(req, res, obj);
      });
      updateDefault = this.updateDefault;
      return app.put("" + profile + "/:id/defaults", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return updateDefault(req, res, obj);
      });
    };

    QuotaController.prototype.detailQuota = function(req, res, obj) {
      var client, id, params, query;
      id = req.params.id;
      params = {
        id: id,
        query: {}
      };
      for (query in req.query) {
        if (query === '_' || query === '_cache') {
          continue;
        }
        params.query[query] = req.query[query];
      }
      client = controllerBase.getClient(req, obj);
      client[obj.alias].defaults(params, function(err, data) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    QuotaController.prototype.updateDefault = function(req, res, obj) {
      var client, params;
      params = {
        data: req.body,
        id: req.params.id
      };
      client = controllerBase.getClient(req, obj);
      client[obj.alias].update(params, function(err, data) {
        if (err) {
          logger.error("Failed to update " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    return QuotaController;

  })(controllerBase);

  module.exports = QuotaController;

}).call(this);

//# sourceMappingURL=quotaController.js.map
