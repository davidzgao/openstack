(function() {
  'use strict';
  var events;

  events = require('events');

  module.exports.utils = {

    /**
      * Get public URL by mode,
      * if not exist, return null.
      * Example:
      *        var utils = require('utils').utils
      *        utils.getURLByCatalog(catalog, mode);
      *
      *     @param {Object} catalog this must be a Array
      *     @param {String} mode service type
      *     @returns {*}
     */
    getURLByCatalog: function(catalog, mode, adminURL) {
      var end, _i, _len;
      if (adminURL == null) {
        adminURL = false;
      }
      for (_i = 0, _len = catalog.length; _i < _len; _i++) {
        end = catalog[_i];
        if (end.type === mode && !adminURL) {
          return end.endpoints[0].publicURL;
        } else if (end.type === mode) {
          return end.endpoints[0].adminURL;
        }
      }
    },
    getURLByRegions: function(regions, mode, adminURL) {
      var endpoint, endpoints, region, _i, _j, _len, _len1;
      if (adminURL == null) {
        adminURL = false;
      }
      for (_i = 0, _len = regions.length; _i < _len; _i++) {
        region = regions[_i];
        if (region.active === true) {
          endpoints = region.endpoints;
          for (_j = 0, _len1 = endpoints.length; _j < _len1; _j++) {
            endpoint = endpoints[_j];
            if (endpoint.type === mode && !adminURL) {
              return endpoint.publicURL;
            } else if (endpoint.type === mode) {
              return endpoint.adminURL;
            }
          }
        } else {
          continue;
        }
      }
    },
    getURLByRegion: function(regions, regionName, mode, adminURL) {
      var endpoint, endpoints, region, _i, _j, _len, _len1;
      if (adminURL == null) {
        adminURL = false;
      }
      for (_i = 0, _len = regions.length; _i < _len; _i++) {
        region = regions[_i];
        if (region.name === regionName) {
          endpoints = region.endpoints;
          for (_j = 0, _len1 = endpoints.length; _j < _len1; _j++) {
            endpoint = endpoints[_j];
            if (endpoint.type === mode && !adminURL) {
              return endpoint.publicURL;
            } else if (endpoint.type === mode) {
              return endpoint.adminURL;
            }
          }
        } else {
          continue;
        }
      }
    },
    getStoreHash: function(currentRegion, resource) {
      var hash;
      if (resource) {
        hash = "" + currentRegion + "-" + resource;
      } else {
        hash = "" + currentRegion + "-";
      }
      return hash;
    },

    /**
      * Format date time as 'YY-MM-D h:m:s'
     */
    getFormatTime: function() {
      var date, day, hour, minutes, month, seconds, year, _ref, _ref1, _ref2, _ref3;
      date = new Date();
      year = date.getFullYear();
      month = date.getMonth() + 1;
      day = date.getDate();
      hour = date.getHours();
      minutes = date.getMinutes();
      seconds = date.getSeconds();
      day = ((_ref = day < 10) != null ? _ref : {
        "0": ""
      }) + day;
      hour = ((_ref1 = hour < 10) != null ? _ref1 : {
        "0": ""
      }) + hour;
      minutes = ((_ref2 = minutes < 10) != null ? _ref2 : {
        "0": ""
      }) + minutes;
      seconds = ((_ref3 = seconds < 10) != null ? _ref3 : {
        "0": ""
      }) + seconds;
      return "" + year + "-" + month + "-" + day + " " + hour + ":" + minutes + ":" + seconds;
    },
    isEmptyObject: function(obj) {
      return !Object.keys(obj).length;
    },
    urlHashEncode: function(encoder, originStr, type) {
      if (!type) {
        type = "base64";
      }
      return encoder.update(originStr).digest(type);
    },
    getLimit: function(request) {
      var limit, limitFrom, limitTo;
      limit = void 0;
      if (request.query) {
        limitFrom = request.query.limit_from;
        limitTo = request.query.limit_to;
        if (limitFrom && limitTo) {
          limit = {
            from: Number(limitFrom) + 1,
            to: Number(limitTo) + 1
          };
        }
      }
      return limit;
    },
    resourceCheck: function() {
      events.EventEmitter.call(this);
    }
  };

}).call(this);

//# sourceMappingURL=utils.js.map
