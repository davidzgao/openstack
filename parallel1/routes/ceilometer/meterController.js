(function() {
  'use strict';
  var MeterController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  MeterController = (function(_super) {
    __extends(MeterController, _super);

    function MeterController() {
      var options;
      options = {
        service: 'metering',
        profile: 'meters',
        alias: 'meter'
      };
      MeterController.__super__.constructor.call(this, options);
    }

    MeterController.prototype.config = function(app) {
      var obj, show;
      obj = this;
      show = this.show;
      this.debug = 'production' !== app.get('env');
      return app.get("/" + this.profile + "/:item", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return show(req, res, obj);
      });
    };

    MeterController.prototype.show = function(req, res, obj) {
      var client, item, params, query;
      item = req.params.item;
      query = req.query;
      params = {
        item: item,
        query: query
      };
      client = controllerBase.getClient(req, obj);
      return client[obj.alias].getMeters(params, function(err, data) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    return MeterController;

  })(controllerBase);

  module.exports = MeterController;

}).call(this);

//# sourceMappingURL=meterController.js.map
