# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase
volumeController = require('../cinder/volumeController')
redis = require('ecutils').redis
storage = require('ecutils').storage
async = require('async')
utils = require('../../utils/utils').utils
extend = require('util')._extend
util = require('util')
events = require('events')
lodash = require('lodash')

###*
 # server controller.
###
class ServerController extends controllerBase

  constructor: () ->
    options =
      service: 'compute'
      profile: 'servers'
    super(options)
    @redisClient = redis.connect(
      'redis_host': redisConf.host
      'redis_password': redisConf.pass
      'redis_port': redisConf.port)

  config: (app) ->
    obj = @
    action = @action
    attach = @attach
    metadataUpdata = @metadataUpdata
    addinterface = @addinterface
    removeinterface = @removeinterface
    detach = @detach
    app.post "/#{@profile}/:id/os-volume_attachments", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      attach req, res, obj
    app.put "/#{@profile}/:id/metadata/:key" , (req, res) ->
      if not controllerBase.checkToken req, res
        return
      metadataUpdata req, res, obj
    app.del "/#{@profile}/:id/os-volume_attachments/:volumeId", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      detach req, res, obj
    app.post "/#{@profile}/:id/action", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      action req, res, obj
    app.post "/#{@profile}/:id/os-interface", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      addinterface req, res, obj
    app.delete "/#{@profile}/:id/os-interface/:portId", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      removeinterface req, res, obj
    queryByIds = @queryByIds
    app.get "/#{@profile}/query", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      queryByIds req, res, obj
    search = @search
    app.get "/#{@profile}/search", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      search req, res, obj

    @debug = 'production' != app.get('env')
    @storage = new storage.Storage({
      redis_client: @redisClient
      debug: @debug
    })
    super(app)

  queryByIds: (req, res, obj) ->
    try
      storeHash = utils.getStoreHash(req.session.current_region, 'instances')
      options =
        'ids': JSON.parse req.query.ids
        'fields': JSON.parse req.query.fields
        'resource_type': storeHash
    catch err
      res.send err, controllerBase._ERROR_400
      return

    obj.storage.getObjectsByIds options, (err, replies) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        res.send replies

  @queryRelative: (options, callback) ->
    storage = options.storage
    if options.params
      storage.getObjectsByIds options.params, (err, data) ->
        if err
          resource_type = options.params.resource_type
          logger.error "Failed to get #{resource_type} as:", err
          callback err, []
        else
          callback null, data
    else if options.keyValue
      storage.getObjectsByKeyValues options.keyValue, (err, data) ->
        if err
          resource_type = options.keyValue.resource_type
          logger.error "Failed to get #{resource_type} as:", err
          callback err, []
        else
          callback null, data
    else
      storage.getObjects options, (err, data) ->
        if err
          logger.error "Failed to get #{options.resource_type} as:", err
          callback err, []
        else
          callback null, data

  @grouping: (instances, req, obj) ->
    tmp = []
    (next = (_i, len, cb) ->
      if _i < len
        userId = instances.data[_i].user_id
        if userId != req.session.user.id
          async.parallel [
            (cb) ->
              obj.storage.getObject
                resource_type: "user_groups"
                id: userId
              , (err, groups) ->
                if err
                  cb(err, null)
                else
                  cb(null, groups)
            (cb) ->
              obj.storage.getObject
                resource_type: "user_groups"
                id: req.session.user.id
              , (err, groups) ->
                if err
                  cb(err, null)
                else
                  cb(null, groups)
          ], (err, results) ->
            userGroups = {}
            for result in results
              if result
                result.groups = JSON.parse result.groups
                userGroups[result.id] = []
                for group in result.groups
                  userGroups[result.id].push group.id
            if userGroups[req.session.user.id]
              for groupId in userGroups[req.session.user.id]
                if userGroups[userId] and groupId in userGroups[userId]
                  tmp.push instances.data[_i]
            next(_i+1, len, cb)
        else
          tmp.push instances.data[_i]
          next(_i+1, len, cb)
      else
        cb(tmp)

    )(0, instances.data.length, () ->
      instances.data = tmp
    )

  @assembleQuery: (instances, req) ->
    userIds = []
    projectIds = []
    flavorIds = []
    imageIds = []
    for instance in instances
      if !instance
        continue
      if instance.user_id not in userIds
        userIds.push instance.user_id
      if instance.tenant_id not in projectIds
        projectIds.push instance.tenant_id
      flavor = JSON.parse(instance.flavor)
      if flavor.id not in flavorIds
        flavorIds.push flavor.id
      if not instance.image
        continue
      image = JSON.parse(instance.image)
      if image.id not in imageIds
        imageIds.push image.id
    userOptions =
      params:
        ids: userIds
        fields: ['name']
        resource_type: 'users'
    projectOptions =
      params:
        ids: projectIds
        fields: ['name']
        resource_type: 'projects'
    flavorHash = utils.getStoreHash(req.session.current_region, 'flavors')
    imageHash = utils.getStoreHash(req.session.current_region, 'images')
    volumeHash = utils.getStoreHash(req.session.current_region, 'volumes')
    flavorOptions =
      params:
        ids: flavorIds
        fields: ['name', 'vcpus', 'ram', 'disk']
        resource_type: flavorHash
    imageOptions =
      params:
        ids: imageIds
        fields: ['name']
        resource_type: imageHash
    volumeOptions =
      resource_type: volumeHash
      query:
        status: 'in-use'
    snapshotsOptions =
      keyValue:
        resource_type: imageHash
        query_cons:
          'properties@image_type': ['snapshot']
    return [userOptions, projectOptions, flavorOptions, imageOptions,
    volumeOptions, snapshotsOptions]

  @queryCallback: (instances, results, res, err) ->
    if err
      res.send instances
    else if not instances
      res.send instances
    else
      userMap = results[0]
      projectMap = results[1]
      flavorMap = results[2]
      if results.length >= 4
        imageMap = results[3]
      if results.length > 4
        volumes = results[4].data
      if results.length >= 6
        snapshots = results[5].data
      date_time = (new Date()).getTime()
      if instances.data
        if instances.data instanceof Array
          for instance in instances.data
            if !instance
              continue
            instance.serverTime = date_time
            if userMap[instance.user_id]
              instance.user_name = userMap[instance.user_id].name
            if projectMap[instance.tenant_id]
              instance.project_name = projectMap[instance.tenant_id].name
            flavor = JSON.parse(instance.flavor)
            flavorDetail = flavorMap[flavor.id]
            if flavorDetail
              instance.flavor_name = flavorDetail.name
              instance.vcpus = flavorDetail.vcpus
              instance.ram = flavorDetail.ram
            if instance.image
              image = JSON.parse(instance.image)
              if not utils.isEmptyObject(imageMap)
                if imageMap[image.id]
                  instance.image_name = imageMap[image.id].name
                else
                  instance.image_name = null
            else
              instance.image_name = null
            if volumes
              instance.volumes = []
              for vol in volumes
                attach = JSON.parse(vol.attachments)
                for ship in attach
                  if ship.server_id == instance.id
                    ship.volume_name = vol.display_name
                    instance.volumes.push ship
      else
        if userMap[instances.user_id]
          instances.user_name = userMap[instances.user_id].name
        if projectMap[instances.tenant_id]
          instances.project_name = projectMap[instances.tenant_id].name
        flavor = JSON.parse(instances.flavor)
        flavorDetail = flavorMap[flavor.id]
        instances.serverTime = date_time
        if flavorDetail
          instances.flavor_name = flavorDetail.name
          instances.vcpus = flavorDetail.vcpus
          instances.ram = flavorDetail.ram
          instances.disk = flavorDetail.disk
        if not instances.image
          instances.image_name = null
        else
          image = JSON.parse(instances.image)
          if not utils.isEmptyObject(imageMap)
            instances.image_name = imageMap[image.id].name

        # Inject the volume attach info into instance
        if volumes
          instances.volumes = []
          for vol in volumes
            attach = JSON.parse(vol.attachments)
            for ship in attach
              if ship.server_id == instances.id
                ship.volume_name = vol.display_name
                instances.volumes.push ship
      res.send instances

  metadataUpdata: (req, res, obj) ->
    params =
      data: req.body
      id: req.params.id
      key: req.params.key
    client = controllerBase.getClient req, obj
    client[obj.alias].metadataUpdata params, (err, data) ->
      if err
        logger.error "Failed to update #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        param =
          id: req.params.id
        client[obj.alias].get param, (err, instance) ->
          if err
            logger.warn "Failed to get #{obj.alias} as: ", err
            res.send data
          else
            storeHash = utils.getStoreHash(req.session.current_region, 'instances')
            opts =
              hash_prefix: storeHash
              data: instance
              fetch_at: (new Date()).getTime()
              need_fresh: true
            obj.storage.updateObject opts, (err, server) ->
              res.send server
    return


  index: (req, res, obj, detail=false) ->
    limit = utils.getLimit(req)
    if not req.query.all_tenants
      req.query.tenant_id = req.session.tenant.id
    else
      delete req.query.all_tenants
    # Delete limit and cache query
    delete req.query.limit_from
    delete req.query.limit_to
    delete req.query._
    delete req.query._cache
    if req.query.host
      req.query["OS-EXT-SRV-ATTR:host"] = req.query.host
      delete req.query.host
    if req.query.hypervisor_hostname
      req.query["OS-EXT-SRV-ATTR:hypervisor_hostname"] = req.query.hypervisor_hostname
      delete req.query.hypervisor_hostname
    if req.query['reverse_match_items']
      reverseItems = req.query['reverse_match_items']
      delete req.query['reverse_match_items']
      query = extend({}, req.query)
    else
      query = extend({}, req.query)
    storeHash = utils.getStoreHash(req.session.current_region, 'instances')
    obj.storage.getObjects
      resource_type: storeHash
      query: query
      limit: limit
      reverse_items: reverseItems
      debug: obj.debug
    , (err, instances) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        if req.headers['x-platform'] == 'Unicorn'
          ServerController.grouping(instances, req, obj)
        opts = ServerController.assembleQuery(instances.data, req)
        userOpts = opts[0]
        proOpts = opts[1]
        flavorOpts = opts[2]
        imageOpts = opts[3]
        volOpts = opts[4]
        userOpts.storage = obj.storage
        proOpts.storage = obj.storage
        flavorOpts.storage = obj.storage
        volOpts.storage = obj.storage
        imageOpts.storage = obj.storage
        async.map([userOpts, proOpts, flavorOpts, imageOpts, volOpts],
        ServerController.queryRelative, (err, results) ->
          ServerController.queryCallback instances, results, res, err
        )

  search: (req, res, obj) ->
    limit = utils.getLimit(req)
    if not req.query.all_tenants
      req.query.tenant_id = req.session.tenant.id
    else
      delete req.query.all_tenants
    delete req.query.limit_from
    delete req.query.limit_to
    delete req.query._
    delete req.query._cache
    query_cons = {}
    if req.query.searchKey and req.query.searchValue
      query_cons[req.query.searchKey] = [req.query.searchValue]
    if req.query.tenant_id
      query_cons['tenant_id'] = [req.query.tenant_id]
    storeHash = utils.getStoreHash(req.session.current_region, 'instances')
    obj.storage.getObjectsByKeyValues
      resource_type: storeHash
      query_cons: query_cons
      require_detail: req.query.require_detail
      condition_relation: 'and'
      limit: limit
      debug: obj.debug
    , (err, instances) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        opts = ServerController.assembleQuery(instances.data, req)
        userOpts = opts[0]
        proOpts = opts[1]
        flavorOpts = opts[2]
        imageOpts = opts[3]
        volOpts = opts[4]
        userOpts.storage = obj.storage
        proOpts.storage = obj.storage
        flavorOpts.storage = obj.storage
        volOpts.storage = obj.storage
        imageOpts.storage = obj.storage
        async.map([userOpts, proOpts, flavorOpts, imageOpts, volOpts],
        ServerController.queryRelative, (err, results) ->
          ServerController.queryCallback instances, results, res, err
        )

  show: (req, res, obj) ->
    storeHash = utils.getStoreHash(req.session.current_region, 'instances')
    obj.storage.getObject
      resource_type: storeHash
      id: req.params.id
    , (err, instance) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        if !instance
          res.send instance
        opts = ServerController.assembleQuery([instance], req)
        userOpts = opts[0]
        proOpts = opts[1]
        flaOpts = opts[2]
        imgOpts = opts[3]
        volOpts = opts[4]
        userOpts.storage = obj.storage
        proOpts.storage = obj.storage
        flaOpts.storage = obj.storage
        volOpts.storage = obj.storage
        imgOpts.storage = obj.storage
        async.map([userOpts, proOpts, flaOpts, imgOpts, volOpts],
        ServerController.queryRelative, (err, results) ->
          ServerController.queryCallback instance, results, res, err
        )

  create: (req, res, obj) ->
    params =
      data: req.body
    client = controllerBase.getClient req, obj
    delete params.data.version
    client[obj.alias].create params, (err, server)->
      if err
        logger.error "Failed to create #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        params =
          id:server.id
        client[obj.alias].get params, (err, instance) ->
          if err
            logger.error "Failed to get #{obj.alias} as: ", err
            res.send err, obj._ERROR_400
          storeHash = utils.getStoreHash(req.session.current_region, 'instances')
          opts =
            hash_prefix: storeHash
            data: instance
          obj.storage.updateObject opts, (err, server) ->
            res.send server
    ###
    reqData = lodash.clone(req.body)
    params =
      data: reqData
    if req.body.imageRef and not req.body.dev_mapping_v2
      dump =
        size: reqData.volume_size
        display_name: reqData.name + "-system volume"
        display_description: 'This is a system volume.'
        volume_type: reqData.volume_type
        imageRef: reqData.imageRef
      volParams =
        data: dump
      count = req.body.max_count
      countAdd = count + 1
      volWaitCreated = []
      mins = waitVolumeCreatedMins or 6

      ResourceCheck = () ->
        events.EventEmitter.call(this)
        return
      util.inherits(utils.resourceCheck, events.EventEmitter)
      ec = new utils.resourceCheck()
      volWaitIgnore = []
      instanceName = req.body.name
      intervalHandler = null

      volumeCtrl = new volumeController()
      volClient = controllerBase.getClient req, volumeCtrl
      # FIXME(liuhaobo): The following need to optimizate
      createVolume = (callback) ->
        # This function is used to create volume.
        volClient['volumes'].create volParams, (err, volume) ->
          volParams.data = volParams.data.volume
          if err
            callback err, null
          else
            callback null, volume

      getVolInfos = (volume, callback) ->
        # This function is used to get volume info.
        volumeId = volume.id
        volParams =
          id: volume.id
          query: {}
        volClient['volumes'].get volParams, (err, volume) ->
          if err
            callback err, null
          else
            callback null, volume

      # Initialize the series list
      bootVolumes = while countAdd -= 1
        createVolume

      async.series(bootVolumes, (errs, volumes) ->
        # Execute createVolume sequentially.
        waitTime = volumes.length * 1000 * 60 * mins
        intervalTime = 2000
        instanceIndex = 1

        if errs
          logger.error errs
          res.send "Meet error when create boot volume", obj._ERROR_400
        else
          res.send "Success to create boot volumes"
          waitInterval = () ->
            # Wait volume created successfully.
            async.map(volumes, getVolInfos, (errs, vols) ->
              if volWaitIgnore.length == count
                clearInterval(intervalHandler)
              for vol, index in vols
                if vol and vol.status == 'available'
                  if vol.id not in volWaitIgnore
                    ec.emit('volume_available', vol.id)
                    volWaitIgnore.push vol.id
            )
            return

          ec.on('volume_available', (volumeId) ->
            # If a volume created successfully, use this volume
            # to boot a instance.
            block_device_mapping_v2 = [{
              boot_index: 0
              uuid: volumeId
              source_type: 'volume'
              destination_type: 'volume'
              delete_on_termination: true
            }]

            reqData.block_device_mapping_v2 = block_device_mapping_v2
            reqData.imageRef = undefined
            reqData.name = instanceName + '-' + instanceIndex++ if count > 1
            reqData.max_count = 1
            reqData.min_count = 1
            novaClient = controllerBase.getClient req, obj
            if not reqData.version
              novaClient.url = novaClient.url.replace "v2", "v2.1"
            params.use_raw_data = true
            params.data.user_data = req.body.user_data
            novaClient[obj.alias].create params, (err, server)->
              if err
                logger.error "Failed to create #{obj.alias} as: ", err
            return
          )
          timeOut = () ->
            # If time out, cancel the interval function.
            clearInterval(intervalHandler)
          # Start loop
          intervalHandler = setInterval(waitInterval, intervalTime)
          setTimeout(timeOut, waitTime)
        return
      )
      return
    else
      req.body.block_device_mapping_v2[0].delete_on_termination = true
      client = controllerBase.getClient req, obj
      if not req.body.version
        client.url = client.url.replace "v2", "v2.1"
      client[obj.alias].create params, (err, server)->
        if err
          logger.error "Failed to create #{obj.alias} as:", err
          res.send err, obj._ERROR_400
        else
          params =
            id: server.id
          client[obj.alias].get params, (err, instance) ->
            if err
              logger.error "Failed to get #{obj.alias} as:", err
              res.send err, obj._ERROR_400
            storeHash = utils.getStoreHash(req.session.current_region, 'instances')
            opts =
              hash_prefix: storeHash
              data: instance
            obj.storage.updateObject opts, (err, server) ->
              res.send server
    ###

  del: (req, res, obj) ->
    params =
      id: req.params.id
    client = controllerBase.getClient req, obj
    client[obj.alias].del params, (err, data, status) ->
      if err
        logger.error "Failed to delete #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        params =
          id: params.id
        client[obj.alias].get params, (err, instance) ->
          if err
            opts =
              hash_prefix: 'instances'
              object_id: req.params.id
            obj.storage.deleteObject opts, (server) ->
              logger.debug "Delete the server from redis."
              res.send "", status.status
            return
          storeHash = utils.getStoreHash(req.session.current_region, 'instances')
          opts =
            hash_prefix: storeHash
            data: instance
          obj.storage.updateObject opts, (server) ->
            res.send server
    return

  @action_dispatcher: (actionKey) ->
    actionMap = {
      'reboot': 'reboot',
      'migrate': 'migrate',
      'pause': 'pause',
      'unpause': 'unpause',
      'lock': 'lock',
      'unlock': 'unlock',
      'suspend': 'suspend',
      'resume': 'resume',
      'rescue': 'rescue',
      'resize': 'resize',
      'unrescue': 'unrescue',
      'restore': 'restore',
      'forceDelete': 'forceDelete',
      'createImage': 'snapshot',
      'addFloatingIp': 'add_floating_ip',
      'removeFloatingIp': 'remove_floating_ip',
      'os-stop': 'stop',
      'os-start': 'start',
      'os-getConsoleOutput': 'getLog',
      'os-getVNCConsole': 'getConsole',
      'os-resetState': 'set_active_state',
      'avhosts': 'getAvailableHost',
      'live-migrate': 'live_migrate',
      'addSecurityGroup': 'add_security_group',
      'removeSecurityGroup': 'remove_security_group',
    }
    return actionMap[actionKey]

  action: (req, res, obj) ->
    actionKey = Object.keys(req.body)[0]
    params =
      data: req.body[actionKey]
      id: req.params.id
    client = controllerBase.getClient req, obj
    actionFunc = ServerController.action_dispatcher(actionKey)
    client[obj.alias][actionFunc] params, (err, data) ->
      if err
        res.send err, obj._ERROR_400
      else
        ignoredActions = [
          'os-getConsoleOutput',
          'os-getVNCConsole',
          'avhosts'
        ]
        if actionKey in ignoredActions
          res.send data
        else
          args =
            id: req.params.id
          storeHash = utils.getStoreHash(req.session.current_region, 'instances')
          client[obj.alias].get args, (err, detail) ->
            opts =
              hash_prefix: storeHash
              data: detail
            obj.storage.updateObject opts, (server) ->
              logger.debug "Server detail success saved!"
              res.send server
    return

  detach: (req, res, obj) ->
    params =
      id: req.params.id
      data:
        volumeId: req.params.volumeId
    client = controllerBase.getClient req, obj
    client[obj.alias].detach params, (err, data) ->
      if err
        res.send err, obj._ERROR_400
      else
        res.send data
    return

  attach: (req, res, obj) ->
    params =
      id: req.params.id
      data: req.body
    client = controllerBase.getClient req, obj
    client[obj.alias].attach params, (err, data) ->
      if err
        res.send err, obj._ERROR_400
      else
        res.send data
    return

  addinterface: (req, res, obj) ->
    params =
      id: req.params.id
      data: req.body
    client = controllerBase.getClient req, obj
    client[obj.alias].addInterface params, (err, data) ->
      if err
        res.send err, obj._ERROR_400
      else
        res.send data
    return

  removeinterface: (req, res, obj) ->
    params =
      id: req.params.id
      data: req.params.portId
    client = controllerBase.getClient req, obj
    client[obj.alias].removeInterface params, (err, data) ->
      if err
        res.send err, obj._ERROR_400
      else
        res.send data
    return

module.exports = ServerController
