'use strict'

controllerBase = require('../controller').ControllerBase
redis = require('ecutils').redis
storage = require('ecutils').storage


###
# The V2 API for keystone projects(tenants).
# For hidden the confusion for project and tenant,
# replace the tenants of projects and the projectV3
# stand for V3 projects API.
###
class ProjectController extends controllerBase

  constructor: () ->
    options =
      service: 'identity'
      profile: 'projects'
    super(options)
    @redisClient = redis.connect({'redis_host': redisConf.host})

  config: (app) ->
    obj = this
    @debug = 'production' != app.get('env')
    @storage = new storage.Storage({
      redis_client: @redisClient
      debug: @debug
    })

    queryByIds = @queryByIds
    app.get "/#{@profile}/query", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      queryByIds req, res, obj

    super(app)

  queryByIds: (req, res, obj) ->
    try
      options =
        'ids': JSON.parse req.query.ids
        'fields': JSON.parse req.query.fields
        'resource_type': 'projects'
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
    obj.storage.getObjects
      resource_type: 'projects'
      query: req.query
      limit: limit
      debug: obj.debug
    , (err, projects) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        res.send projects

  show: (req, res, obj) ->
    obj.storage.getObject
      resource_type: 'projects'
      id: req.params.id
    , (err, project) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        res.send project

module.exports = ProjectController
