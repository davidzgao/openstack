(function() {
  'use strict';
  var RuleController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;


  /**
    * server controller.
   */

  RuleController = (function(_super) {
    __extends(RuleController, _super);

    function RuleController() {
      var options;
      options = {
        service: 'maintenance',
        profile: 'rules'
      };
      RuleController.__super__.constructor.call(this, options);
    }

    RuleController.prototype.config = function(app) {
      var obj, template;
      obj = this;
      template = this.template;
      app.get("/" + this.profile + "/:id/template", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return template(req, res, obj);
      });
      return RuleController.__super__.config.call(this, app);
    };

    RuleController.prototype.template = function(req, res, obj) {
      var client, params;
      params = {
        data: {},
        id: req.params.id
      };
      client = controllerBase.getClient(req, obj);
      client[obj.alias].template(params, function(err, data) {
        if (err) {
          return res.send(err, obj._ERROR_400);
        } else {
          return res.send(data);
        }
      });
    };

    return RuleController;

  })(controllerBase);

  module.exports = RuleController;

}).call(this);

//# sourceMappingURL=ruleController.js.map
