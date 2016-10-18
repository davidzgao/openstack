(function() {
  'use strict';
  var RegionController, controllerBase, openclient, redis, storage,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;

  openclient = require('openclient');

  RegionController = (function(_super) {
    __extends(RegionController, _super);

    function RegionController() {
      var options;
      options = {
        service: 'identity',
        profile: 'regions',
        baseUrl: global.cloudAPIs.keystone.v3
      };
      RegionController.__super__.constructor.call(this, options);
    }

    RegionController.prototype.config = function(app) {
      var index, obj, switchRegion;
      obj = this;
      index = this.index;
      switchRegion = this.switchRegion;
      app.get("/regions", function(req, res) {
        return index(req, res, obj);
      });
      app.post("/regions/switch", function(req, res) {
        return switchRegion(req, res, obj);
      });
      return RegionController.__super__.config.call(this, app);
    };

    RegionController.prototype.getClient = function(req, obj) {
      var baseUrl, service, version;
      baseUrl = obj.baseUrl;
      version = global.cloudAPIs.version['project'];
      service = openclient.getAPI("openstack", obj.service, version);
      obj.client = new service({
        url: baseUrl,
        scoped_token: req.session.token,
        tenant: req.session.tenant.id,
        debug: obj.debug
      });
      return obj.client;
    };

    RegionController.prototype.index = function(req, res, obj) {
      var client;
      if (!controllerBase.checkToken(req, res)) {
        return;
      }
      client = obj.getClient(req, obj);
      client['regions'].all({}, function(err, data, status) {
        var region, service, _i, _j, _len, _len1, _ref;
        if (!req.session.regions) {
          res.send([]);
          return;
        }
        _ref = req.session.regions;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          service = _ref[_i];
          if (!data) {
            return;
          }
          for (_j = 0, _len1 = data.length; _j < _len1; _j++) {
            region = data[_j];
            if (region.id === service.name) {
              service.extra = region.extra;
            }
          }
        }
        return res.send(req.session.regions);
      });
    };

    RegionController.prototype.switchRegion = function(req, res, obj) {
      var region, _i, _len, _ref;
      if (!controllerBase.checkToken(req, res)) {
        return;
      }
      if (!req.body.region) {
        return;
      }
      _ref = req.session.regions;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        region = _ref[_i];
        if (region.name === req.body.region) {
          region.active = true;
          req.session.current_region = region.name;
        } else {
          region.active = false;
        }
      }
      res.send(req.session.regions);
    };

    return RegionController;

  })(controllerBase);

  module.exports = RegionController;

}).call(this);

//# sourceMappingURL=regionController.js.map
