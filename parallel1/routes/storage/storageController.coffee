'use strict'

controllerBase = require('../controller').ControllerBase

class StorageController
    config: (app) ->
      obj = @
      status = @status
      usage = @usage
      topology = @topology

      app.get "/storage/status", (req, res) ->
        if not controllerBase.checkToken req, res
          return
        status req, res, obj

      app.get "/storage/usage", (req, res) ->
        if not controllerBase.checkToken req, res
          return
        usage req, res, obj

      app.get "/storage/topology", (req, res) ->
        if not controllerBase.checkToken req, res
          return
        topology req, res, obj

    @_getStorageClient: (regionName) ->
      if storageConf[regionName]
        currentStorageConf = storageConf[regionName]
        backend = require("./backends/#{currentStorageConf.storageType}")
        backendClient = new backend(currentStorageConf)
        return backendClient
      # TODO(ZhengYue): Add error hanler

    status: (req, res, obj) ->
      # The steps for get backend storage status:
      # 1. Get region_name from session;
      # 2. Get backend storage type from config file by region_name
      # 3. Confirm storage API
      # 4. Initial the storage request object;
      # 5. Get status from storage API

      currentRegion = req.session.current_region
      client = StorageController._getStorageClient(currentRegion)

      stor_name = storageConf[currentRegion]['storageName']
      if stor_name
        # Use cached storage name
        client.status stor_name, (err, status) ->
          if err
            res.send {status: 'WARN'}
          else
            res.send {status: status}
      else
        client.info (storageName) ->
          # NOTE(ZhengYue): Save storage name in config
          storageConf[currentRegion]['storageName'] = storageName
          client.status storageName, (err, status) ->
            if err
              res.send {status: 'WARN'}
            else
              res.send {status: status}
      return

    ###
    #   Get usage of storage backend.
    #   The storage backend wapper need return data as format:
    #    {
    #      'total': 1234455,
    #      'free':  34343,
    #      'unit': 'B'
    #    }
    ###
    usage: (req, res, obj) ->
      currentRegion = req.session.current_region
      client = StorageController._getStorageClient(currentRegion)
      stor_name = storageConf[currentRegion]['storageName']
      if stor_name
        # Use cached storage name
        client.usage stor_name, (err, usage) ->
          if err
            res.send usage
          else
            res.send usage
      else
        client.info (storageName) ->
          # NOTE(ZhengYue): Save storage name in config
          storageConf[currentRegion]['storageName'] = storageName
          client.usage storageName, (err, usage) ->
            if err
              res.send usage
            else
              res.send usage
      return

    topology: (req, res, obj) ->
      # NOTE(ZhengYue): No Implement
      res.send {}
      return

module.exports = StorageController
