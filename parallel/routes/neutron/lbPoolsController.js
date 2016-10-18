(function() {
  'use strict';
  var PoolController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  PoolController = (function(_super) {
    __extends(PoolController, _super);

    function PoolController() {
      var options;
      options = {
        service: 'network',
        profile: 'lb/pools',
        alias: 'pools'
      };
      PoolController.__super__.constructor.call(this, options);
    }

    PoolController.prototype.config = function(app) {
      var assginMonitor, obj;
      obj = this;
      assginMonitor = this.assginMonitor;
      app.post("/lb/pools/:id/health_monitors", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return assginMonitor(req, res, obj);
      });
      return PoolController.__super__.config.call(this, app);
    };

    PoolController.prototype.assginMonitor = function(req, res, obj) {
      var client, params;
      params = {
        id: req.params.id,
        data: req.body
      };
      client = controllerBase.getClient(req, obj);
      console.log(client);
      client[obj.alias].assginHealthMonitor(params, function(err, data) {
        if (err) {
          return res.send(err, err.status);
        } else {
          return res.send(data);
        }
      });
    };

    return PoolController;

  })(controllerBase);

  module.exports = PoolController;

}).call(this);

//# sourceMappingURL=lbPoolsController.js.map
