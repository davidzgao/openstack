(function() {
  'use strict';
  var VolumeController, async, controllerBase, redis, storage, utils,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  controllerBase = require('../controller').ControllerBase;

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;

  async = require('async');

  utils = require('../../utils/utils').utils;


  /**
    * server controller.
   */

  VolumeController = (function(_super) {
    __extends(VolumeController, _super);

    function VolumeController() {
      var options;
      options = {
        service: 'volume',
        profile: 'volumes'
      };
      this.redisClient = redis.connect({
        'redis_host': redisConf.host
      });
      this.storage = new storage.Storage({
        redis_client: this.redisClient,
        debug: this.debug
      });
      VolumeController.__super__.constructor.call(this, options);
    }

    VolumeController.prototype.config = function(app) {
      var action, obj, queryByIds, search;
      obj = this;
      action = this.action;
      app.post("/" + this.profile + "/:id/action", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return action(req, res, obj);
      });
      queryByIds = this.queryByIds;
      app.get("/" + this.profile + "/query", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return queryByIds(req, res, obj);
      });
      search = this.search;
      app.get("/" + this.profile + "/search", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return search(req, res, obj);
      });
      this.debug = 'production' !== app.get('env');
      this.storage = new storage.Storage({
        redis_client: this.redisClient,
        debug: this.debug
      });
      return VolumeController.__super__.config.call(this, app);
    };

    VolumeController.prototype.queryByIds = function(req, res, obj) {
      var err, options, storeHash;
      try {
        storeHash = utils.getStoreHash(req.session.current_region, 'volumes');
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

    VolumeController.prototype.index = function(req, res, obj, detail) {
      var limit, storeHash;
      if (detail == null) {
        detail = false;
      }
      limit = utils.getLimit(req);
      delete req.query.limit_from;
      delete req.query.limit_to;
      delete req.query._;
      delete req.query._cache;
      if (!req.query.all_tenants) {
        req.query.tenant_id = req.session.tenant.id;
      } else {
        delete req.query.all_tenants;
      }
      storeHash = utils.getStoreHash(req.session.current_region, 'volumes');
      return obj.storage.getObjects({
        resource_type: storeHash,
        query: req.query,
        limit: limit,
        debug: obj.debug
      }, function(err, volumes) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          if (req.headers['x-platform'] === 'Unicorn') {
            return VolumeController.grouping(volumes, req, obj, function(volumes) {
              return res.send(volumes);
            });
          } else {
            return res.send(volumes);
          }
        }
      });
    };

    VolumeController.prototype.search = function(req, res, obj) {
      var limit, query_cons, storeHash;
      limit = utils.getLimit(req);
      delete req.query.limit_from;
      delete req.query.limit_to;
      delete req.query._;
      delete req.query._cache;
      query_cons = {};
      if (req.query.searchKey && req.query.searchValue) {
        query_cons[req.query.searchKey] = [req.query.searchValue];
      }
      if (req.query.tenant_id) {
        query_cons['tenant_id'] = [req.query.tenant_id];
      }
      storeHash = utils.getStoreHash(req.session.current_region, 'volumes');
      return obj.storage.getObjectsByKeyValues({
        resource_type: storeHash,
        query_cons: query_cons,
        require_detail: req.query.require_detail,
        condition_relation: 'and',
        limit: limit,
        debug: obj.debug
      }, function(err, volumes) {
        if (err) {
          logger.error("Failed to get volume as: ", err);
          return res.send(err, err.status);
        } else {
          return res.send(volumes);
        }
      });
    };

    VolumeController.prototype.show = function(req, res, obj) {
      var storeHash;
      storeHash = utils.getStoreHash(req.session.current_region, 'volumes');
      return obj.storage.getObject({
        resource_type: storeHash,
        id: req.params.id
      }, function(err, volume) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(volume);
        }
      });
    };

    VolumeController.prototype.create = function(req, res, obj) {
      var client, params;
      params = {
        data: req.body
      };
      client = controllerBase.getClient(req, obj);
      client[obj.alias].create(params, function(err, volume) {
        var opts, storeHash;
        if (err) {
          logger.error("Failed to create " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          volume.tenant_id = req.session.tenant.id;
          storeHash = utils.getStoreHash(req.session.current_region, 'volumes');
          opts = {
            hash_prefix: storeHash,
            data: volume
          };
          return obj.storage.updateObject(opts, function(err, vol) {
            return res.send(volume);
          });
        }
      });
    };

    VolumeController.prototype.del = function(req, res, obj) {
      var client, params;
      params = {
        id: req.params.id
      };
      client = controllerBase.getClient(req, obj);
      client[obj.alias].del(params, function(err, data) {
        if (err) {
          logger.error("Failed to delete " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          params = {
            id: params.id
          };
          return client[obj.alias].get(params, function(err, volume) {
            var opts, storeHash;
            if (err) {
              logger.error("Failed to get " + obj.alias + " as: ", err);
              res.send(err, obj._ERROR_400);
            }
            storeHash = utils.getStoreHash(req.session.current_region, 'volumes');
            opts = {
              hash_prefix: storeHash,
              data: volume
            };
            return obj.storage.updateObject(opts, function(val) {
              return res.send(val);
            });
          });
        }
      });
    };

    VolumeController.action_dispatcher = function(actionKey) {
      var actionMap;
      actionMap = {
        'os-volume_upload_image': 'volume_upload_image'
      };
      return actionMap[actionKey];
    };

    VolumeController.prototype.action = function(req, res, obj) {
      var actionFunc, actionKey, client, params;
      actionKey = Object.keys(req.body)[0];
      params = {
        data: req.body[actionKey],
        id: req.params.id
      };
      client = controllerBase.getClient(req, obj);
      actionFunc = VolumeController.action_dispatcher(actionKey);
      return client[obj.alias][actionFunc](params, function(err, data) {
        if (err) {
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data, 200);
        }
      });
    };

    VolumeController.grouping = function(volumes, req, obj, callback) {
      var currentId, next, tmp;
      tmp = [];
      currentId = req.session.user.id;
      return (next = function(_i, len, cb) {
        var userId;
        if (_i < len) {
          userId = volumes.data[_i].user_id;
          if (userId !== currentId) {
            return async.parallel([
              function(cb) {
                return obj.storage.getObject({
                  resource_type: "user_groups",
                  id: userId
                }, function(err, groups) {
                  if (err) {
                    return cb(err, null);
                  } else {
                    return cb(null, groups);
                  }
                });
              }, function(cb) {
                return obj.storage.getObject({
                  resource_type: "user_groups",
                  id: currentId
                }, function(err, groups) {
                  if (err) {
                    return cb(err, null);
                  } else {
                    return cb(null, groups);
                  }
                });
              }
            ], function(err, results) {
              var group, groupId, result, userGroups, _j, _k, _l, _len, _len1, _len2, _ref, _ref1;
              userGroups = {};
              for (_j = 0, _len = results.length; _j < _len; _j++) {
                result = results[_j];
                if (result) {
                  result.groups = JSON.parse(result.groups);
                  userGroups[result.id] = [];
                  _ref = result.groups;
                  for (_k = 0, _len1 = _ref.length; _k < _len1; _k++) {
                    group = _ref[_k];
                    userGroups[result.id].push(group.id);
                  }
                }
              }
              if (userGroups[currentId]) {
                _ref1 = userGroups[currentId];
                for (_l = 0, _len2 = _ref1.length; _l < _len2; _l++) {
                  groupId = _ref1[_l];
                  if (userGroups[userId] && __indexOf.call(userGroups[userId], groupId) >= 0) {
                    tmp.push(volumes.data[_i]);
                  }
                }
              }
              return next(_i + 1, len, cb);
            });
          } else {
            tmp.push(volumes.data[_i]);
            return next(_i + 1, len, cb);
          }
        } else {
          return cb(tmp);
        }
      })(0, volumes.data.length, function() {
        volumes.data = tmp;
        return callback(volumes);
      });
    };

    return VolumeController;

  })(controllerBase);

  module.exports = VolumeController;

}).call(this);

//# sourceMappingURL=volumeController.js.map
