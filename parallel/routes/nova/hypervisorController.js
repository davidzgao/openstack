(function() {
  'use strict';
  var HypervisorController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  HypervisorController = (function(_super) {
    __extends(HypervisorController, _super);

    function HypervisorController() {
      var options;
      options = {
        service: 'compute',
        profile: 'os-hypervisors',
        alias: 'hypervisors'
      };
      HypervisorController.__super__.constructor.call(this, options);
    }

    HypervisorController.prototype.config = function(app) {
      var create, del, index, obj, show, statistic, update;
      obj = this;
      index = this.index;
      show = this.show;
      update = this.update;
      del = this.del;
      create = this.create;
      statistic = this.statistic;
      this.debug = 'production' !== app.get('env');
      app.get("/" + this.profile + "/statistics", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return statistic(req, res, obj);
      });
      app.get("/" + this.profile, function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return index(req, res, obj);
      });
      app.get("/" + this.profile + "/detail", function(req, res) {
        var detail;
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return index(req, res, obj, detail = true);
      });
      app.get("/" + this.profile + "/:id", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return show(req, res, obj);
      });
      app.put("/" + this.profile + "/:id", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return update(req, res, obj);
      });
      app.post("/" + this.profile, function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return create(req, res, obj);
      });
      app.del("/" + this.profile + "/:id", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return del(req, res, obj);
      });
    };

    HypervisorController.prototype.statistic = function(req, res, obj) {
      var client;
      client = controllerBase.getClient(req, obj);
      client[obj.alias].statistic({}, function(err, stats) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(stats.hypervisor_statistics);
        }
      });
    };

    return HypervisorController;

  })(controllerBase);

  module.exports = HypervisorController;

}).call(this);

//# sourceMappingURL=hypervisorController.js.map
