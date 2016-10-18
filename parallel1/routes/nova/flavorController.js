(function() {
  'use strict';
  var FlavorController, controllerBase, openclient, redis, storage, utils,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  openclient = require('openclient');

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;

  utils = require('../../utils/utils').utils;


  /**
    * flavor controller.
   */

  FlavorController = (function(_super) {
    __extends(FlavorController, _super);

    function FlavorController() {
      var options;
      options = {
        service: 'compute',
        profile: 'os-flavors',
        alias: 'flavors'
      };
      FlavorController.__super__.constructor.call(this, options);
      this.redisClinet = redis.connect({
        'redis_host': redisConf.host
      });
    }

    FlavorController.prototype.config = function(app) {
      var obj, queryByIds, search;
      obj = this;
      queryByIds = this.queryByIds;
      search = this.search;
      app.get("/" + this.profile + "/query", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return queryByIds(req, res, obj);
      });
      app.get("/" + this.profile + "/search", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return search(req, res, obj);
      });
      this.debug = 'production' !== app.get('env');
      this.storage = new storage.Storage({
        redis_client: this.redisClinet,
        debug: this.debug
      });
      return FlavorController.__super__.config.call(this, app);
    };

    FlavorController.prototype.queryByIds = function(req, res, obj) {
      var err, options, storeHash;
      try {
        storeHash = utils.getStoreHash(req.session.current_region, 'flavors');
        options = {
          'ids': JSON.parse(req.query.ids),
          'fields': JSON.parse(req.query.fields),
          'resource_type': storeHash
        };
      } catch (_error) {
        err = _error;
        res.send(err, controllerBase._ERROR_400);
        return;
      }
      return obj.storage.getObjectsByIds(options, function(err, replies) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(replies);
        }
      });
    };

    FlavorController.prototype.index = function(req, res, obj, detail) {
      var limit, storeHash;
      if (detail == null) {
        detail = false;
      }
      limit = utils.getLimit(req);
      delete req.query.limit_from;
      delete req.query.limit_to;
      delete req.query._;
      delete req.query._cache;
      storeHash = utils.getStoreHash(req.session.current_region, 'flavors');
      return obj.storage.getObjects({
        resource_type: storeHash,
        query: req.query,
        limit: limit,
        debug: obj.debug
      }, function(err, flavors) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(flavors);
        }
      });
    };

    FlavorController.prototype.show = function(req, res, obj) {
      var storeHash;
      storeHash = utils.getStoreHash(req.session.current_region, 'flavors');
      return obj.storage.getObject({
        resource_type: storeHash,
        id: req.params.id
      }, function(err, flavor) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(flavor);
        }
      });
    };

    FlavorController.getBaseUrl = function(req, obj, admin) {
      var region, regionName, regions, retionName, _i, _len;
      regions = req.session.regions;
      retionName = '';
      for (_i = 0, _len = regions.length; _i < _len; _i++) {
        region = regions[_i];
        if (region.active) {
          regionName = region.name;
          break;
        }
      }
      if (req.session.adminBack) {
        regions = req.session.adminBack.regions;
      }
      obj.baseUrl = utils.getURLByRegion(regions, regionName, obj.service, admin);
      return obj.baseUrl;
    };

    FlavorController.getClient = function(req, obj, admin) {
      var baseUrl, service, tenant, token, version;
      if (admin == null) {
        admin = false;
      }
      token = req.session.token;
      tenant = req.session.tenant.id;
      if (req.session.adminBack) {
        token = req.session.adminBack.token;
        tenant = req.session.adminBack.tenant.id;
      }
      baseUrl = FlavorController.getBaseUrl(req, obj, admin);
      version = global.cloudAPIs.version[obj.service];
      service = openclient.getAPI("openstack", obj.service, version);
      obj.client = new service({
        url: baseUrl,
        scoped_token: token,
        tenant: tenant,
        debug: obj.debug
      });
      return obj.client;
    };

    FlavorController.prototype.create = function(req, res, obj) {
      var client, params;
      params = {
        data: req.body
      };
      client = FlavorController.getClient(req, obj);
      client[obj.alias].create(params, function(err, flavor) {
        var opts, storeHash;
        if (err) {
          logger.error("Failed to create " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          storeHash = utils.getStoreHash(req.session.current_region, 'flavors');
          opts = {
            hash_prefix: storeHash,
            data: flavor
          };
          return obj.storage.updateObject(opts, function() {
            return res.send(flavor);
          });
        }
      });
    };

    FlavorController.prototype.update = function(req, res, obj) {
      var client, params;
      params = {
        data: req.body,
        id: req.params.id
      };
      client = FlavorController.getClient(req, obj);
      client[obj.alias].update(params, function(err, data) {
        if (err) {
          logger.error("Failed to update " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    FlavorController.prototype.search = function(req, res, obj) {
      var limit, limitFrom, limitTo, query_cons, storeHash;
      limitFrom = req.query.limit_from;
      limitTo = req.query.limit_to;
      limit = void 0;
      if (limitFrom && limitTo) {
        limit = {
          from: Number(limitFrom),
          to: Number(limitTo)
        };
      }
      delete req.query.limit_from;
      delete req.query.limit_to;
      delete req.query._;
      delete req.query._cache;
      query_cons = {};
      if (req.query.searchKey && req.query.searchValue) {
        query_cons[req.query.searchKey] = [req.query.searchValue];
      }
      if (req.query.tenant_id) {
        query_cons['tenant_id'] = req.query.tenant_id;
      }
      storeHash = utils.getStoreHash(req.session.current_region, 'flavors');
      return obj.storage.getObjectsByKeyValues({
        resource_type: storeHash,
        query_cons: query_cons,
        require_detail: req.query.require_detail,
        condition_relation: 'and',
        limit: limit,
        debug: obj.debug
      }, function(err, flavors) {
        if (err) {
          logger.error("Failed to get flavors as: ", err);
          return res.send(err, err.status);
        } else {
          return res.send(flavors);
        }
      });
    };

    return FlavorController;

  })(controllerBase);

  module.exports = FlavorController;

}).call(this);

//# sourceMappingURL=flavorController.js.map
