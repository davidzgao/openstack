(function() {
  'use strict';
  var WorkflowController, controllerBase, redis, storage,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;


  /**
    * workflow controller.
   */

  WorkflowController = (function(_super) {
    __extends(WorkflowController, _super);

    function WorkflowController() {
      var options;
      options = {
        service: 'workflow',
        profile: 'workflow-requests'
      };
      WorkflowController.__super__.constructor.call(this, options);
      this.redisClient = redis.connect({
        'redis_host': redisConf.host,
        'redis_password': redisConf.pass,
        'redis_port': redisConf.port
      });
    }

    WorkflowController.prototype.config = function(app) {
      var approve, edit, obj, resourceCheck;
      obj = this;
      approve = this.approve;
      edit = this.edit;
      resourceCheck = this.resourceCheck;
      app.get("/" + this.profile + "/:id/edit", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return edit(req, res, obj);
      });
      app.put("/" + this.profile + "/:id", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return approve(req, res, obj);
      });
      app.post("/resource_check", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return resourceCheck(req, res, obj);
      });
      this.debug = 'production' !== app.get('env');
      this.storage = new storage.Storage({
        redis_client: this.redisClient,
        debug: this.debug
      });
      return WorkflowController.__super__.config.call(this, app);
    };

    WorkflowController.prototype.approve = function(req, res, obj) {
      var client, imageId, imagePass, params;
      imageId = void 0;
      imagePass = void 0;
      if (req.body.content) {
        imageId = req.body.content.image;
      }
      if (imageId) {
        obj.storage.getObject({
          resource_type: 'images',
          id: imageId
        }, function(err, image) {
          var client, imageMeta, params;
          if (err) {
            logger.error("Failed to get image");
          } else {
            if (image) {
              imageMeta = JSON.parse(image.properties);
              imagePass = imageMeta.password;
            } else {
              imagePass = void 0;
            }
          }
          if (imagePass) {
            req.body.content.admin_pass = imagePass;
            params = {
              data: req.body,
              id: req.params.id
            };
            client = controllerBase.getClient(req, obj);
            return client[obj.alias].update(params, function(err, data) {
              return res.send(data);
            });
          } else {
            params = {
              data: req.body,
              id: req.params.id
            };
            client = controllerBase.getClient(req, obj);
            return client[obj.alias].update(params, function(err, data) {
              return res.send(data);
            });
          }
        });
      } else {
        params = {
          data: req.body,
          id: req.params.id
        };
        client = controllerBase.getClient(req, obj);
        client[obj.alias].update(params, function(err, data) {
          return res.send(data);
        });
      }
    };

    WorkflowController.prototype.edit = function(req, res, obj) {
      var client, params;
      params = {
        id: req.params.id
      };
      client = controllerBase.getClient(req, obj);
      return client[obj.alias].edit(params, function(err, data) {
        if (err) {
          res.send(err, err.status);
        } else {
          res.send(data);
        }
      });
    };

    WorkflowController.prototype.resourceCheck = function(req, res, obj) {
      var client, params;
      params = {
        data: req.body
      };
      client = controllerBase.getClient(req, obj);
      return client[obj.alias].resourceCheck(params, function(err, data) {
        if (err) {
          res.send(err, err.status);
        } else {
          res.send(data);
        }
      });
    };

    return WorkflowController;

  })(controllerBase);

  module.exports = WorkflowController;

}).call(this);

//# sourceMappingURL=workflowController.js.map
