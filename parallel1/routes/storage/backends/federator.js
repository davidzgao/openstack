(function() {
  var FederatorClient, async, request;

  request = require('request');

  async = require('async');

  process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

  FederatorClient = (function() {
    function FederatorClient(conf) {
      var API, AUTH, authBuffer;
      API = conf.API;
      this.options = {
        base_uri: "" + API.protocol + "://" + API.host + ":" + API.port,
        host: API.host,
        adapter: conf.adapter
      };
      this.request_headers = conf.requestHeaders;
      authBuffer = new Buffer(conf.auth);
      AUTH = authBuffer.toString('base64');
      this.request_headers['Authorization'] = "Basic " + AUTH;
    }

    FederatorClient.prototype._assemble_get_options = function(lo) {
      var HEADERS, options;
      HEADERS = this.request_headers;
      options = {
        headers: HEADERS,
        uri: lo,
        method: 'GET'
      };
      return options;
    };

    FederatorClient.prototype.info = function(callback) {
      var HEADERS, HOST, obj, reqBody, reqOptions;
      reqBody = {
        'metadata': {
          'adapter': "" + this.options.adapter,
          'connection': {
            'host': "" + this.options.host
          }
        }
      };
      HOST = this.options.host;
      HEADERS = this.request_headers;
      reqOptions = {
        headers: HEADERS,
        uri: "" + this.options.base_uri + "/fed_storage",
        method: 'PUT',
        body: JSON.stringify(reqBody)
      };
      obj = this;
      return request(reqOptions, function(err, response, body) {
        var loReq, loca, static_filter;
        if (err) {
          callback(err);
        }
        loca = response.headers.location;
        static_filter = '?filter="by_adapter_name"&key=["cdmi-dpl"]';
        if (!loca) {
          loca = "" + reqOptions.uri + static_filter;
        }
        loReq = obj._assemble_get_options(loca);
        return request(loReq, function(error, res, stInfo) {
          var storage, storageName, storages;
          storageName = '';
          if (!stInfo) {
            return callback(storageName);
          }
          stInfo = JSON.parse(stInfo);
          storages = stInfo['metadata']['map'];
          for (storage in storages) {
            if (storages[storage]) {
              storageName = storage;
            }
          }
          return callback(storageName);
        });
      });
    };

    FederatorClient.prototype.status = function(storageName, callback) {
      var obj, reqOptions, uri;
      if (!storageName) {
        callback('ERROR');
      }
      obj = this;
      uri = "" + this.options.base_uri + "/fed_storage/" + storageName;
      reqOptions = obj._assemble_get_options(uri);
      return request(reqOptions, function(err, response, body) {
        var info, state;
        if (err) {
          callback('ERROR', null);
        }
        info = JSON.parse(body);
        state = info['metadata']['state'];
        if (state === 'Online') {
          state = 'OK';
        }
        return callback(null, state);
      });
    };

    FederatorClient.prototype.queryPool = function(options, callback) {
      return request(options, function(err, res, poolInfo) {
        if (err) {
          console.log(err, 'error at query pool');
          callback(err, []);
        } else {
          poolInfo = JSON.parse(poolInfo);
          return callback(null, poolInfo);
        }
      });
    };

    FederatorClient.prototype.usage = function(storageName, callback) {
      var POOLURI, obj, reqBody, reqOptions;
      if (!storageName) {
        callback('ERROR');
      }
      reqBody = {
        'metadata': {
          'storage': "" + storageName
        }
      };
      POOLURI = "" + this.options.base_uri + "/fed_pool";
      reqOptions = {
        headers: this.request_headers,
        uri: POOLURI,
        method: 'PUT',
        body: JSON.stringify(reqBody)
      };
      obj = this;
      return request(reqOptions, function(err, res, body) {
        var lo, loOptions;
        if (err) {
          return callback('ERROR');
        } else {
          lo = res.headers.location;
          if (!lo) {
            lo = POOLURI + '?filter="by_storage_name"&key=["' + storageName + '"]';
          }
          loOptions = obj._assemble_get_options(lo);
          return request(loOptions, function(error, response, data) {
            var pool, poolDetail, poolInfo, poolUri, pools;
            if (error) {
              console.log(error, 'error at detail pool');
              callback('ERROR', null);
              return;
            }
            poolInfo = JSON.parse(data);
            pools = poolInfo['metadata']['map'];
            poolDetail = [];
            for (pool in pools) {
              poolUri = "" + POOLURI + "/" + pool;
              poolDetail.push(obj._assemble_get_options(poolUri));
            }
            if (poolDetail.length > 0) {
              return async.map(poolDetail, obj.queryPool, function(err, results) {
                var capacity, detail, freeSize, index, totalSize, usage;
                if (err) {
                  return callback('ERROR', null);
                } else {
                  totalSize = 0;
                  freeSize = 0;
                  detail = [];
                  for (index in results) {
                    poolInfo = results[index]['metadata'];
                    if (poolInfo['state'] !== 'Online') {
                      continue;
                    }
                    capacity = poolInfo['profile']['capacity'];
                    totalSize += capacity['totalSize'];
                    freeSize += capacity['freeSize'];
                    poolDetail = {
                      'totalSize': capacity['totalSize'],
                      'freeSize': capacity['freeSize'],
                      'displayName': poolInfo['displayName'],
                      'status': poolInfo['state'],
                      'provision': {
                        'peakIOPS': poolInfo['provision']['peakIOPS']
                      }
                    };
                    detail.push(poolDetail);
                  }
                  usage = {
                    total: totalSize,
                    free: freeSize,
                    unit: 'B',
                    detail: detail
                  };
                  return callback(null, usage);
                }
              });
            }
          });
        }
      });
    };

    return FederatorClient;

  })();

  module.exports = FederatorClient;

}).call(this);

//# sourceMappingURL=federator.js.map
