(function() {
  'use strict';
  var GroupController, controllerBase, crypto, openclient, redis, storage,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  openclient = require('openclient');

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;

  crypto = require('crypto');

  GroupController = (function(_super) {
    __extends(GroupController, _super);

    function GroupController() {
      var options;
      options = {
        service: 'identity',
        profile: 'groups',
        baseUrl: global.cloudAPIs.keystone.v3
      };
      GroupController.__super__.constructor.call(this, options);
      this.redisClient = redis.connect({
        'redis_host': redisConf.host
      });
    }

    GroupController.prototype.config = function(app) {
      var obj, search;
      obj = this;
      search = this.search;
      this.debug = 'production' !== app.get('env');
      this.storage = new storage.Storage({
        redis_client: this.redisClient,
        debug: this.debug
      });
      return GroupController.__super__.config.call(this, app);
    };

    GroupController.getClient = function(req, obj, token, tenant_id) {
      var baseUrl, service, version;
      baseUrl = obj.baseUrl;
      version = global.cloudAPIs.version[obj.service];
      service = openclient.getAPI("openstack", obj.service, "3.0");
      if (req.session.tenant && req.session.token) {
        obj.client = new service({
          url: baseUrl,
          scoped_token: req.session.token,
          tenant: req.session.tenant.id,
          debug: obj.debug
        });
      } else {
        obj.client = new service({
          url: baseUrl,
          scoped_token: token,
          tenant: tenant_id,
          debug: true
        });
      }
      return obj.client;
    };

    GroupController.prototype.index = function(req, res, obj, detail) {
      var limit, limitFrom, limitTo;
      if (detail == null) {
        detail = false;
      }
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
      return obj.storage.getObjects({
        resource_type: 'groups',
        limit: limit,
        debug: obj.debug
      }, function(err, groups) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(groups);
        }
      });
    };

    GroupController.prototype.create = function(req, res, obj) {
      var client, params;
      params = {
        data: req.body
      };
      client = GroupController.getClient(req, obj);
      client[obj.alias].create(params, function(err, data) {
        var opts;
        if (err) {
          logger.error("Failed to create group: ", err);
          return res.send(err, err.status);
        } else {
          try {
            opts = {
              hash_prefix: 'groups',
              data: data
            };
            return obj.storage.updateObject(opts, function(groups) {
              logger.debug("Update the groups from redis.");
              return res.send(data);
            });
          } catch (_error) {
            return res.send(data);
          }
        }
      });
    };

    GroupController.prototype.del = function(req, res, obj) {
      var client, params;
      params = {
        id: req.params.id
      };
      client = GroupController.getClient(req, obj);
      client[obj.alias].del(params, function(err, data) {
        var opts;
        if (err) {
          logger.error("Failed to delete " + obj.alias + " as: ", err);
          return res.send(err, err.status);
        } else {
          opts = {
            hash_prefix: 'groups',
            object_id: req.params.id
          };
          return obj.storage.deleteObject(opts, function(user) {
            logger.debug("Delete the group from redis.");
            return res.send(data);
          });
        }
      });
    };

    GroupController.prototype.update = function(req, res, obj) {
      var client, params;
      params = {
        data: {
          group: req.body
        },
        id: req.params.id
      };
      client = GroupController.getClient(req, obj);
      client[obj.alias].update(params, function(err, data) {
        var group, opts;
        if (err) {
          logger.error("Failed to update group info.");
          return res.send(err, err.status);
        } else {
          group = data.group;
          opts = {
            hash_prefix: 'groups',
            data: group
          };
          return obj.storage.updateObject(opts, function(group) {
            res.send(data);
            return logger.debug("Success to update user detal!");
          });
        }
      });
    };

    return GroupController;

  })(controllerBase);

  module.exports = GroupController;

}).call(this);

//# sourceMappingURL=groupsController.js.map
