(function() {
  'use strict';
  var TemplateController, controllerBase, redis, storage,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;


  /**
    * template controller.
   */

  TemplateController = (function(_super) {
    __extends(TemplateController, _super);

    function TemplateController() {
      var options;
      options = {
        service: 'workflow',
        profile: 'load_template'
      };
      TemplateController.__super__.constructor.call(this, options);
    }

    TemplateController.prototype.config = function(app) {
      var load, obj;
      obj = this;
      load = this.load;
      app.get("/load_template/:id", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return load(req, res, obj);
      });
      this.debug = 'production' !== app.get('env');
      return TemplateController.__super__.config.call(this, app);
    };

    TemplateController.prototype.load = function(req, res, obj) {
      var client, params;
      params = {
        id: req.params.id
      };
      client = controllerBase.getClient(req, obj);
      client[obj.alias].load_template(params, function(err, data) {
        if (err) {
          return res.send(err, err.status);
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
