# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase
redis = require('ecutils').redis
storage = require('ecutils').storage
async = require('async')
utils = require('../../utils/utils').utils

###*
 # server controller.
###
class VolumeController extends controllerBase

  constructor: () ->
    options =
      service: 'volume'
      profile: 'volumes'
    @redisClient = redis.connect({'redis_host': redisConf.host})
    @storage = new storage.Storage({
      redis_client: @redisClient
      debug: @debug
    })
    super(options)

  config: (app) ->
    obj = @
    action = @action
    app.post "/#{@profile}/:id/action", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      action req, res, obj

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
      storeHash = utils.getStoreHash(req.session.current_region, 'volumes')
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

  index: (req, res, obj, detail=false) ->
    limit = utils.getLimit(req)
    # Delete limit and cache query
    delete req.query.limit_from
    delete req.query.limit_to
    delete req.query._
    delete req.query._cache
    if not req.query.all_tenants
      req.query.tenant_id = req.session.tenant.id
    else
      delete req.query.all_tenants
    storeHash = utils.getStoreHash(req.session.current_region, 'volumes')
    obj.storage.getObjects
      resource_type: storeHash
      query: req.query
      limit: limit
      debug: obj.debug
    , (err, volumes) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        if req.headers['x-platform'] == 'Unicorn'
          VolumeController.grouping(volumes, req, obj, (volumes) ->
            res.send volumes
          )
        else
          res.send volumes

  search: (req, res, obj) ->
    limit = utils.getLimit(req)
    delete req.query.limit_from
    delete req.query.limit_to
    delete req.query._
    delete req.query._cache
    query_cons = {}
    if req.query.searchKey and req.query.searchValue
      query_cons[req.query.searchKey] = [req.query.searchValue]
    if req.query.tenant_id
      query_cons['tenant_id'] = [req.query.tenant_id]
    storeHash = utils.getStoreHash(req.session.current_region, 'volumes')
    obj.storage.getObjectsByKeyValues
      resource_type: storeHash
      query_cons: query_cons
      require_detail: req.query.require_detail
      condition_relation: 'and'
      limit: limit
      debug: obj.debug
    , (err, volumes) ->
      if err
        logger.error "Failed to get volume as: ", err
        res.send err, err.status
      else
        res.send volumes

  show: (req, res, obj) ->
    storeHash = utils.getStoreHash(req.session.current_region, 'volumes')
    obj.storage.getObject
      resource_type: storeHash
      id: req.params.id
    , (err, volume) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        res.send volume

  create: (req, res, obj) ->
    params =
      data: req.body
    client = controllerBase.getClient req, obj
    client[obj.alias].create params, (err, volume)->
      if err
        logger.error "Failed to create #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        volume.tenant_id = req.session.tenant.id
        storeHash = utils.getStoreHash(req.session.current_region, 'volumes')
        opts =
          hash_prefix: storeHash
          data: volume
        obj.storage.updateObject opts, (err, vol) ->
          res.send volume
    return

  del: (req, res, obj) ->
    params =
      id: req.params.id
    client = controllerBase.getClient req, obj
    client[obj.alias].del params, (err, data) ->
      if err
        logger.error "Failed to delete #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        params =
          id: params.id
        client[obj.alias].get params, (err, volume) ->
          if err
            logger.error "Failed to get #{obj.alias} as: ", err
            res.send err, obj._ERROR_400
          storeHash = utils.getStoreHash(req.session.current_region, 'volumes')
          opts =
            hash_prefix: storeHash
            data: volume
          obj.storage.updateObject opts, (val) ->
            res.send val
    return

  @action_dispatcher: (actionKey) ->
    actionMap =
      'os-volume_upload_image': 'volume_upload_image'
    return actionMap[actionKey]

  action: (req, res, obj) ->
    actionKey = Object.keys(req.body)[0]
    params =
      data: req.body[actionKey]
      id: req.params.id
    client = controllerBase.getClient req, obj
    actionFunc = VolumeController.action_dispatcher(actionKey)
    client[obj.alias][actionFunc] params, (err, data) ->
      if err
        res.send err, obj._ERROR_400
      else
        res.send data, 200

  @grouping: (volumes, req, obj, callback) ->
    tmp = []
    currentId = req.session.user.id
    (next = (_i, len, cb) ->
      if _i < len
        userId = volumes.data[_i].user_id
        if userId != currentId
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
                id: currentId
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
            if userGroups[currentId]
              for groupId in userGroups[currentId]
                if userGroups[userId] and groupId in userGroups[userId]
                  tmp.push volumes.data[_i]
            next(_i+1, len, cb)
        else
          tmp.push volumes.data[_i]
          next(_i+1, len, cb)
      else
        cb(tmp)
    )(0, volumes.data.length, () ->
      volumes.data = tmp
      callback(volumes)
    )

module.exports = VolumeController
