(function() {
  'use strict';
  var ImageController, async, controllerBase, formidable, redis, storage, utils,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  controllerBase = require('../controller').ControllerBase;

  formidable = require('../../utils/incoming_form');

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;

  async = require('async');

  utils = require('../../utils/utils').utils;


  /**
    * image controller.
   */

  ImageController = (function(_super) {
    __extends(ImageController, _super);

    function ImageController() {
      var options;
      options = {
        service: 'image',
        profile: 'images'
      };
      ImageController.__super__.constructor.call(this, options);
      this.redisClient = redis.connect({
        'redis_host': redisConf.host,
        'redis_password': redisConf.pass,
        'redis_port': redisConf.port
      });
    }

    ImageController.prototype.config = function(app) {
      var download, obj, profile, search;
      obj = this;
      download = this.download;
      profile = "/" + this.profile;
      search = this.search;
      if (this.adder) {
        profile = "/" + this.adder + "/" + this.profile;
      }
      app.get("" + profile + "/:imageId/download", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return download(req, res, obj);
      });
      app.get("" + profile + "/search", function(req, res) {
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
      return ImageController.__super__.config.call(this, app);
    };

    ImageController.queryRelative = function(options, callback) {
      storage = options.storage;
      return storage.getObjectsByIds(options.params, function(err, data) {
        var resource_type;
        if (err) {
          resource_type = options.params.resource_type;
          logger.error("Failed to get " + resource_type + " as: ", err);
          return callback(err, []);
        } else {
          return callback(null, data);
        }
      });
    };

    ImageController.assembleQuery = function(images) {
      var image, projectIds, projectOptions, _i, _len, _ref;
      projectIds = [];
      for (_i = 0, _len = images.length; _i < _len; _i++) {
        image = images[_i];
        if (_ref = image.owner, __indexOf.call(projectIds, _ref) < 0) {
          projectIds.push(image.owner);
        }
      }
      projectOptions = {
        params: {
          ids: projectIds,
          fields: ['name'],
          resource_type: 'projects'
        }
      };
      return [projectOptions];
    };

    ImageController.prototype.index = function(req, res, obj, detail) {
      var limit, listCallback, queryStatus, query_cons, storeHash;
      if (detail == null) {
        detail = false;
      }
      limit = utils.getLimit(req);
      if (!req.query.all_tenants) {
        req.query.owner = req.session.tenant.id;
      } else {
        delete req.query.all_tenants;
      }
      delete req.query.limit_from;
      delete req.query.limit_to;
      delete req.query._;
      delete req.query._cache;
      listCallback = function(err, images) {
        var options;
        if (err) {
          logger.error(err);
          return res.send(err, err.code);
        } else {
          options = ImageController.assembleQuery(images.data);
          options[0].storage = obj.storage;
          return async.map(options, ImageController.queryRelative, function(err, results) {
            var image, projectMap, _i, _len, _ref;
            if (err) {
              return res.send(images);
            } else {
              projectMap = results[0];
              _ref = images.data;
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                image = _ref[_i];
                if (projectMap[image.owner]) {
                  image.project_name = projectMap[image.owner].name;
                } else {
                  image.project_name = '';
                }
              }
              return res.send(images);
            }
          });
        }
      };
      queryStatus = ["queued", "saving", "active"];
      if (req.query.ec_image_type) {
        query_cons = {
          ec_image_type: [req.query.ec_image_type]
        };
      } else {
        query_cons = {};
      }
      if (req.query.is_public === 'true') {
        query_cons['is_public'] = ['true'];
      }
      storeHash = utils.getStoreHash(req.session.current_region, 'images');
      if (!req.query.snapshot) {
        query_cons['status'] = queryStatus;
        if (req.query.owner) {
          query_cons['owner'] = [req.query.owner];
        }
        return obj.storage.getObjectsByKeyValues({
          resource_type: storeHash,
          query_cons: query_cons,
          require_detail: true,
          condition_relation: 'and',
          limit: limit,
          debug: obj.debug
        }, function(err, images) {
          return listCallback(err, images);
        });
      } else {
        query_cons['properties@image_type'] = ['snapshot'];
        if (req.query.owner) {
          query_cons['owner'] = [req.query.owner];
        }
        return obj.storage.getObjectsByKeyValues({
          resource_type: storeHash,
          query_cons: query_cons,
          require_detail: true,
          condition_relation: 'and',
          limit: limit,
          debug: obj.debug
        }, function(err, images) {
          return listCallback(err, images);
        });
      }
    };

    ImageController.prototype.search = function(req, res, obj) {
      var limit, listCallback, query_cons, storeHash;
      limit = utils.getLimit(req);
      if (!req.query.all_tenants) {
        req.query.owner = req.session.tenant.id;
      } else {
        delete req.query.all_tenants;
      }
      delete req.query.limit_from;
      delete req.query.limit_to;
      delete req.query._;
      delete req.query._cache;
      listCallback = function(err, images) {
        var options;
        if (err) {
          logger.error(err);
          return res.send(err, err.code);
        } else {
          options = ImageController.assembleQuery(images.data);
          options[0].storage = obj.storage;
          return async.map(options, ImageController.queryRelative, function(err, results) {
            var image, projectMap, _i, _len, _ref;
            if (err) {
              return res.send(images);
            } else {
              projectMap = results[0];
              _ref = images.data;
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                image = _ref[_i];
                if (projectMap[image.owner]) {
                  image.project_name = projectMap[image.owner].name;
                } else {
                  image.project_name;
                }
              }
              return res.send(images);
            }
          });
        }
      };
      query_cons = {};
      if (req.query.searchKey && req.query.searchValue) {
        query_cons[req.query.searchKey] = [req.query.searchValue];
      }
      storeHash = utils.getStoreHash(req.session.current_region, 'images');
      if (!req.query.snapshot) {
        return obj.storage.getObjectsByKeyValues({
          resource_type: storeHash,
          query_cons: query_cons,
          require_detail: req.query.require_detail,
          condition_relation: 'and',
          limit: limit,
          debug: obj.debug
        }, function(err, images) {
          return listCallback(err, images);
        });
      } else {
        query_cons['properties@image_type'] = ['snapshot'];
        return obj.storage.getObjectsByKeyValues({
          resource_type: storeHash,
          query_cons: query_cons,
          require_detail: true,
          condition_relation: 'and',
          limit: limit,
          debug: obj.debug
        }, function(err, images) {
          return listCallback(err, images);
        });
      }
    };

    ImageController.prototype.show = function(req, res, obj) {
      var storeHash;
      storeHash = utils.getStoreHash(req.session.current_region, 'images');
      return obj.storage.getObject({
        resource_type: storeHash,
        id: req.params.id
      }, function(err, image) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(image);
        }
      });
    };

    ImageController.prototype.create = function(req, res, obj) {
      var client, imageMeta, params, uploader;
      imageMeta = req.headers['x-image-meta'] || "{}";
      imageMeta = unescape(imageMeta);
      params = {
        data: JSON.parse(imageMeta)
      };
      client = controllerBase.getClient(req, obj);
      uploader = client[obj.alias].create(params, function(err, img) {
        var imageType, opts, storeHash;
        if (err) {
          logger.error("Failed to create " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          img.status = 'saving';
          if (img.created_at) {
            img.created = img.created_at;
            delete img.created_at;
          }
          if (img.updated_at) {
            img.updated = img.updated_at;
            delete img.updated_at;
          }
          imageType = 'image';
          if (img.properties) {
            imageType = img.properties.image_type || 'image';
          }
          if (img.metadata) {
            imageType = img.metadata.image_type || 'image';
          }
          if (imageType === 'backup' || imageType === 'snapshot') {
            imageType = 'backup';
          }
          img.ec_image_type = imageType;
          storeHash = utils.getStoreHash(req.session.current_region, 'images');
          opts = {
            hash_prefix: storeHash,
            data: img
          };
          return obj.storage.updateObject(opts, function(image) {
            return res.send(image);
          });
        }
      });
      if (uploader) {
        return req.pipe(uploader.request);
      }
    };

    ImageController.prototype.del = function(req, res, obj) {
      var client, params;
      params = {
        id: req.params.id
      };
      client = controllerBase.getClient(req, obj);
      client[obj.alias].del(params, function(err, data) {
        var storeHash;
        if (err) {
          logger.error("Failed to delete " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          storeHash = utils.getStoreHash(req.session.current_region, 'images');
          return obj.storage.getObject({
            resource_type: storeHash,
            id: params.id
          }, function(err, image) {
            var opts;
            if (err) {
              logger.error("Failed to get " + obj.alias + " as: ", err);
              return res.send(err, controllerBase_ERROR_400);
            } else {
              image.status = 'deleting';
              delete image.fetch_at;
              opts = {
                hash_prefix: storeHash,
                data: image,
                fetch_at: image.fetch_at,
                need_fresh: true
              };
              return obj.storage.updateObject(opts, function(img) {
                return res.send(img);
              });
            }
          });
        }
      });
    };

    ImageController.prototype.download = function(req, resp, obj) {
      var client, name, params, request;
      client = controllerBase.getClient(req, obj);
      name = req.query.name;
      params = {
        id: req.params['imageId']
      };
      resp.setHeader('Content-disposition', "attachment; filename=" + name);
      request = client[obj.alias].download(params);
      return request.pipe(resp);
    };

    ImageController.prototype.update = function(req, resp, obj) {
      var client, params;
      params = {
        data: req.body,
        id: req.params.id
      };
      client = controllerBase.getClient(req, obj);
      client[obj.alias].update(params, function(err, img) {
        var imageType, opts;
        if (err) {
          logger.error("Failed to update " + obj.alias + " as: ", err);
          return resp.send(err, obj._ERROR_400);
        } else {
          if (img.created_at) {
            img.created = img.created_at;
            delete img.created_at;
          }
          if (img.updated_at) {
            img.updated = img.updated_at;
            delete img.updated_at;
          }
          imageType = 'image';
          if (img.properties) {
            imageType = img.properties.image_type || 'image';
          }
          if (img.metadata) {
            imageType = img.metadata.image_type || 'image';
          }
          if (imageType === 'backup' || imageType === 'snapshot') {
            imageType = 'backup';
          }
          img.ec_image_type = imageType;
          opts = {
            hash_prefix: 'images',
            data: img
          };
          return obj.storage.updateObject(opts, function(err) {
            if (!err) {
              return resp.send(img);
            } else {
              logger.error(err);
              return resp.send(err, err.code);
            }
          });
        }
      });
    };

    return ImageController;

  })(controllerBase);

  module.exports = ImageController;

}).call(this);

//# sourceMappingURL=imageController.js.map
