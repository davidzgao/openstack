(function() {
  'use strict';
  var ControllerBase, openclient, utils, _DEFAULT_OPS;

  utils = require('../utils/utils').utils;

  openclient = require('openclient');

  _DEFAULT_OPS = {
    service: 'compute',
    profile: 'servers',
    alias: void 0
  };


  /**
    * Base controller which is used to handle http request.
    * By default, handle post/update/get/delete method.
   */

  ControllerBase = (function() {
    ControllerBase.prototype._ERROR_400 = 400;

    function ControllerBase(options) {
      if (options == null) {
        options = _DEFAULT_OPS;
      }
      this.profile = options.profile;
      this.service = options.service;
      this.alias = options.alias || options.profile;
      this.baseUrl = options.baseUrl;
      this.client = void 0;
      this.adder = options.adder || "";
    }


    /**
      * Routes config.
      * list/get/update/del/create Routes
      * are available.
      *
      * @param: {object} express application object.
      *
     */

    ControllerBase.prototype.config = function(app) {
      var create, del, index, obj, profile, show, update;
      obj = this;
      index = this.index;
      show = this.show;
      update = this.update;
      del = this.del;
      create = this.create;
      this.debug = 'production' !== app.get('env');
      profile = "/" + this.profile;
      if (this.adder) {
        profile = "/" + this.adder + "/" + this.profile;
      }
      app.get("" + profile, function(req, res) {
        if (!ControllerBase.checkToken(req, res)) {
          return;
        }
        return index(req, res, obj);
      });
      app.get("" + profile + "/detail", function(req, res) {
        var detail;
        if (!ControllerBase.checkToken(req, res)) {
          return;
        }
        return index(req, res, obj, detail = true);
      });
      app.get("" + profile + "/:id", function(req, res) {
        if (!ControllerBase.checkToken(req, res)) {
          return;
        }
        return show(req, res, obj);
      });
      app.put("" + profile + "/:id", function(req, res) {
        if (!ControllerBase.checkToken(req, res)) {
          return;
        }
        return update(req, res, obj);
      });
      app.post("" + profile, function(req, res) {
        if (!ControllerBase.checkToken(req, res)) {
          return;
        }
        return create(req, res, obj);
      });
      app.del("" + profile + "/:id", function(req, res) {
        if (!ControllerBase.checkToken(req, res)) {
          return;
        }
        return del(req, res, obj);
      });
    };

    ControllerBase.checkToken = function(req, res) {
      if (!req.session || !req.session.token) {
        res.send({
          'auth_error': 'auth error'
        }, 401);
        return false;
      }
      return true;
    };

    ControllerBase.getBaseUrl = function(req, obj, admin) {
      var regions;
      regions = req.session.regions;
      obj.baseUrl = utils.getURLByRegions(regions, obj.service, admin);
      return obj.baseUrl;
    };

    ControllerBase.getClient = function(req, obj, admin) {
      var baseUrl, service, version;
      if (admin == null) {
        admin = false;
      }
      if (obj.getBaseUrl) {
        baseUrl = obj.getBaseUrl(req, obj, admin);
      } else {
        baseUrl = ControllerBase.getBaseUrl(req, obj, admin);
      }
      version = global.cloudAPIs.version[obj.service];
      service = openclient.getAPI("openstack", obj.service, version);
      obj.client = new service({
        url: baseUrl,
        scoped_token: req.session.token,
        tenant: req.session.tenant.id,
        debug: obj.debug
      });
      return obj.client;
    };

    ControllerBase.prototype.index = function(req, res, obj, detail) {
      var client, params, query;
      if (detail == null) {
        detail = false;
      }
      params = {
        query: {}
      };
      for (query in req.query) {
        if (query === '_' || query === '_cache') {
          continue;
        }
        params.query[query] = req.query[query];
      }
      if (detail) {
        params["detail"] = detail;
      }
      client = ControllerBase.getClient(req, obj);
      client[obj.alias].all(params, function(err, data) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    ControllerBase.prototype.show = function(req, res, obj) {
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
      client = ControllerBase.getClient(req, obj);
      client[obj.alias].get(params, function(err, data) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    ControllerBase.prototype.create = function(req, res, obj) {
      var client, params;
      params = {
        data: req.body
      };
      client = ControllerBase.getClient(req, obj);
      client[obj.alias].create(params, function(err, data) {
        if (err) {
          logger.error("Failed to create " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    ControllerBase.prototype.update = function(req, res, obj) {
      var client, params;
      params = {
        data: req.body,
        id: req.params.id
      };
      client = ControllerBase.getClient(req, obj);
      client[obj.alias].update(params, function(err, data) {
        if (err) {
          logger.error("Failed to update " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    ControllerBase.prototype.del = function(req, res, obj) {
      var client, params;
      params = {
        id: req.params.id
      };
      client = ControllerBase.getClient(req, obj);
      client[obj.alias].del(params, function(err, data) {
        if (err) {
          logger.error("Failed to delete " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    return ControllerBase;

  })();

  exports.ControllerBase = ControllerBase;

}).call(this);

//# sourceMappingURL=controller.js.map
