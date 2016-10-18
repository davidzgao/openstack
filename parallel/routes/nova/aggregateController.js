(function() {
  'use strict';
  var AggregateController, controllerBase, redis, storage, utils;

  controllerBase = require('../controller').ControllerBase;

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;

  utils = require('../../utils/utils').utils;


  /**
    * server controller.
   */

  AggregateController = (function() {
    function AggregateController() {
      this.redisClient = redis.connect({
        'redis_host': redisConf.host,
        'redis_password': redisConf.pass,
        'redis_port': redisConf.port
      });
    }

    AggregateController.prototype.config = function(app) {
      var get, obj;
      obj = this;
      get = this.get;
      app.get("/aggregate/:metric/:item", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return get(req, res, obj);
      });
      this.debug = 'production' !== app.get('env');
      return this.storage = new storage.Storage({
        redis_client: this.redisClient,
        debug: this.debug
      });
    };

    AggregateController.prototype.get = function(req, res, obj) {
      var item, limit, limitFrom, limitTo, metric, params, storeHash;
      storage = obj.storage;
      metric = req.params.metric;
      item = req.params.item;
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
      storeHash = "aggregate:" + metric + ":" + item;
      storeHash = utils.getStoreHash(req.session.current_region, storeHash);
      params = {
        resource_type: storeHash,
        query: req.query,
        limit: limit,
        debug: obj.debug,
        sort_field: 'name'
      };
      return storage.getObjects(params, function(err, data) {
        var resource_type;
        if (err) {
          resource_type = options.params.resource_type;
          logger.error("Failed to get " + resource_type + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    return AggregateController;

  })();

  module.exports = AggregateController;

}).call(this);

//# sourceMappingURL=aggregateController.js.map
