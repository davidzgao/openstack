(function() {
  'use strict';
  var PriceController, controllerBase,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  controllerBase = require('../controller').ControllerBase;

  PriceController = (function(_super) {
    __extends(PriceController, _super);

    function PriceController() {
      var options;
      options = {
        service: 'price',
        profile: 'prices'
      };
      PriceController.__super__.constructor.call(this, options);
    }

    return PriceController;

  })(controllerBase);

  module.exports = PriceController;

}).call(this);

//# sourceMappingURL=priceController.js.map
