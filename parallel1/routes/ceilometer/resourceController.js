(function() {
  'use strict';
  var ResourceController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  ResourceController = (function(_super) {
    __extends(ResourceController, _super);

    function ResourceController() {
      var options;
      options = {
        service: 'metering',
        profile: 'resources_per',
        alias: 'resource'
      };
      ResourceController.__super__.constructor.call(this, options);
    }

    ResourceController.prototype.config = function(app) {
      var obj, show;
      obj = this;
      show = this.show;
      this.debug = 'production' !== app.get('env');
      return app.get("/" + this.profile, function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return show(req, res, obj);
      });
    };

    ResourceController.prototype.show = function(req, res, obj) {
      var client, params, query;
      query = req.query;
      params = {
        query: query
      };
      client = controllerBase.getClient(req, obj);
      return client[obj.alias].getResources(params, function(err, data) {
        if (err) {
          logger.error("Failed to get " + obj.alias + " as:", err);
          return res.send(err, controllerBase._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    return ResourceController;

  })(controllerBase);

  module.exports = ResourceController;

}).call(this);

//# sourceMappingURL=resourceController.js.map
