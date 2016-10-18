# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase
redis = require('ecutils').redis
storage = require('ecutils').storage
utils = require('../../utils/utils').utils

###*
 # server controller.
###
class AggregateController

  constructor: () ->
    @redisClient = redis.connect(
      'redis_host': redisConf.host
      'redis_password': redisConf.pass
      'redis_port': redisConf.port)

  config: (app) ->
    obj = @
    get = @get
    app.get "/aggregate/:metric/:item", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      get req, res, obj

    @debug = 'production' != app.get('env')
    @storage = new storage.Storage({
      redis_client: @redisClient
      debug: @debug
    })

  get: (req, res, obj) ->
    storage = obj.storage
    metric = req.params.metric
    item = req.params.item
    limitFrom = req.query.limit_from
    limitTo = req.query.limit_to
    limit = undefined
    if limitFrom and limitTo
      limit =
        from: Number limitFrom
        to: Number limitTo
    # Delete limit and cache query
    delete req.query.limit_from
    delete req.query.limit_to
    delete req.query._
    delete req.query._cache
    storeHash = "aggregate:#{metric}:#{item}"
    storeHash = utils.getStoreHash(req.session.current_region, storeHash)
    params =
      resource_type: storeHash
      query: req.query
      limit: limit
      debug: obj.debug
      sort_field: 'name'
    storage.getObjects params, (err, data) ->
      if err
        resource_type = options.params.resource_type
        logger.error "Failed to get #{resource_type} as:", err
        res.send err, controllerBase._ERROR_400
      else
        res.send data


module.exports = AggregateController
