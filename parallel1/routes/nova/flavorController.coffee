# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase
openclient = require 'openclient'
redis = require('ecutils').redis
storage = require('ecutils').storage
utils = require('../../utils/utils').utils

###*
 # flavor controller.
###
class FlavorController extends controllerBase

  constructor: () ->
    options =
      service: 'compute'
      profile: 'os-flavors'
      alias: 'flavors'
    super(options)
    @redisClinet = redis.connect({'redis_host': redisConf.host})

  config: (app) ->
    obj = @
    queryByIds = @queryByIds
    search = @search
    app.get "/#{@profile}/query", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      queryByIds req, res, obj
    app.get "/#{@profile}/search", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      search req, res, obj

    @debug = 'production' != app.get('env')
    @storage = new storage.Storage({
      redis_client: @redisClinet
      debug: @debug
    })
    super(app)

  queryByIds: (req, res, obj) ->
    try
      storeHash = utils.getStoreHash(req.session.current_region, 'flavors')
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
    storeHash = utils.getStoreHash(req.session.current_region, 'flavors')
    obj.storage.getObjects
      resource_type: storeHash
      query: req.query
      limit: limit
      debug: obj.debug
    , (err, flavors) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        res.send flavors

  show: (req, res, obj) ->
    storeHash = utils.getStoreHash(req.session.current_region, 'flavors')
    obj.storage.getObject
      resource_type: storeHash
      id: req.params.id
    , (err, flavor) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        res.send flavor

  @getBaseUrl: (req, obj, admin) ->
    regions = req.session.regions
    retionName = ''
    for region in regions
      if region.active
        regionName = region.name
        break
    if req.session.adminBack
      regions = req.session.adminBack.regions
    obj.baseUrl = utils.getURLByRegion regions, regionName, obj.service, admin
    return obj.baseUrl

  @getClient: (req, obj, admin=false) ->
    token = req.session.token
    tenant = req.session.tenant.id
    if req.session.adminBack
      token = req.session.adminBack.token
      tenant = req.session.adminBack.tenant.id
    baseUrl = FlavorController.getBaseUrl req, obj, admin
    version = global.cloudAPIs.version[obj.service]
    service = openclient.getAPI "openstack", obj.service, version
    obj.client = new service(
      url: baseUrl
      scoped_token: token
      tenant: tenant
      debug: obj.debug
    )
    obj.client

  create: (req, res, obj) ->
    params =
      data: req.body
    client = FlavorController.getClient req, obj
    client[obj.alias].create params, (err, flavor)->
      if err
        logger.error "Failed to create #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        storeHash = utils.getStoreHash(req.session.current_region, 'flavors')
        opts =
          hash_prefix: storeHash
          data: flavor
        obj.storage.updateObject opts, () ->
          res.send flavor
    return

  update: (req, res, obj) ->
    params =
      data: req.body
      id: req.params.id
    client = FlavorController.getClient req, obj
    client[obj.alias].update params, (err, data) ->
      if err
        logger.error "Failed to update #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        res.send(data)
    return

  search: (req, res, obj) ->
    limitFrom = req.query.limit_from
    limitTo = req.query.limit_to
    limit = undefined
    if limitFrom and limitTo
      limit =
        from: Number limitFrom
        to: Number limitTo
    delete req.query.limit_from
    delete req.query.limit_to
    delete req.query._
    delete req.query._cache
    query_cons = {}
    if req.query.searchKey and req.query.searchValue
      query_cons[req.query.searchKey] = [req.query.searchValue]
    if req.query.tenant_id
      query_cons['tenant_id'] = req.query.tenant_id
    storeHash = utils.getStoreHash(req.session.current_region, 'flavors')
    obj.storage.getObjectsByKeyValues
      resource_type: storeHash
      query_cons: query_cons
      require_detail: req.query.require_detail
      condition_relation: 'and'
      limit: limit
      debug: obj.debug
    , (err, flavors) ->
      if err
        logger.error "Failed to get flavors as: ", err
        res.send err, err.status
      else
        res.send flavors

module.exports = FlavorController
