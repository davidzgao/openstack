(function() {
  'use strict';
  var TemplateController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  TemplateController = (function(_super) {
    __extends(TemplateController, _super);

    function TemplateController() {
      var options;
      options = {
        service: 'deployment',
        profile: 'deploy/template',
        alias: 'deployTemplates'
      };
      TemplateController.__super__.constructor.call(this, options);
    }

    TemplateController.prototype.index = function(req, res, obj, detail) {
      var client, params, query;
      if (detail == null) {
        detail = false;
      }
      params = {
        query: {}
      };
      params.project = req.session.tenant.id;
      for (query in req.query) {
        if (query === '_' || query === '_cache') {
          continue;
        }
        params.query[query] = req.query[query];
      }
      if (detail) {
        params["detail"] = detail;
      }
      client = controllerBase.getClient(req, obj);
      client[obj.alias].all(params, function(err, data) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    TemplateController.prototype.update = function(req, res, obj) {
      var client, params;
      params = {
        project: req.session.tenant.id,
        data: req.body,
        id: req.params.id
      };
      client = controllerBase.getClient(req, obj);
      client[obj.alias].update(params, function(err, data) {
        if (err) {
          logger.error("Failed to update " + obj.alias + " as: ", err);
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    return TemplateController;

  })(controllerBase);

  module.exports = TemplateController;

}).call(this);

//# sourceMappingURL=templateController.js.map
