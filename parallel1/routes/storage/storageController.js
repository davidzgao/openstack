(function() {
  'use strict';
  var StorageController, controllerBase;

  controllerBase = require('../controller').ControllerBase;

  StorageController = (function() {
    function StorageController() {}

    StorageController.prototype.config = function(app) {
      var obj, status, topology, usage;
      obj = this;
      status = this.status;
      usage = this.usage;
      topology = this.topology;
      app.get("/storage/status", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return status(req, res, obj);
      });
      app.get("/storage/usage", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return usage(req, res, obj);
      });
      return app.get("/storage/topology", function(req, res) {
        if (!controllerBase.checkToken(req, res)) {
          return;
        }
        return topology(req, res, obj);
      });
    };

    StorageController._getStorageClient = function(regionName) {
      var backend, backendClient, currentStorageConf;
      if (storageConf[regionName]) {
        currentStorageConf = storageConf[regionName];
        backend = require("./backends/" + currentStorageConf.storageType);
        backendClient = new backend(currentStorageConf);
        return backendClient;
      }
    };

    StorageController.prototype.status = function(req, res, obj) {
      var client, currentRegion, stor_name;
      currentRegion = req.session.current_region;
      client = StorageController._getStorageClient(currentRegion);
      stor_name = storageConf[currentRegion]['storageName'];
      if (stor_name) {
        client.status(stor_name, function(err, status) {
          if (err) {
            return res.send({
              status: 'WARN'
            });
          } else {
            return res.send({
              status: status
            });
          }
        });
      } else {
        client.info(function(storageName) {
          storageConf[currentRegion]['storageName'] = storageName;
          return client.status(storageName, function(err, status) {
            if (err) {
              return res.send({
                status: 'WARN'
              });
            } else {
              return res.send({
                status: status
              });
            }
          });
        });
      }
    };


    /*
     *   Get usage of storage backend.
     *   The storage backend wapper need return data as format:
     *    {
     *      'total': 1234455,
     *      'free':  34343,
     *      'unit': 'B'
     *    }
     */

    StorageController.prototype.usage = function(req, res, obj) {
      var client, currentRegion, stor_name;
      currentRegion = req.session.current_region;
      client = StorageController._getStorageClient(currentRegion);
      stor_name = storageConf[currentRegion]['storageName'];
      if (stor_name) {
        client.usage(stor_name, function(err, usage) {
          if (err) {
            return res.send(usage);
          } else {
            return res.send(usage);
          }
        });
      } else {
        client.info(function(storageName) {
          storageConf[currentRegion]['storageName'] = storageName;
          return client.usage(storageName, function(err, usage) {
            if (err) {
              return res.send(usage);
            } else {
              return res.send(usage);
            }
          });
        });
      }
    };

    StorageController.prototype.topology = function(req, res, obj) {
      res.send({});
    };

    return StorageController;

  })();

  module.exports = StorageController;

}).call(this);

//# sourceMappingURL=storageController.js.map
