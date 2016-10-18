'use strict'

controllerBase = require('../controller').ControllerBase
redis = require('ecutils').redis
storage = require('ecutils').storage
openclient = require 'openclient'


class ProjectController extends controllerBase

  constructor: () ->
    options =
      service: 'identity'
      profile: 'projectsV3'
      baseUrl: global.cloudAPIs.keystone.v3
    super(options)
    @redisClient = redis.connect({'redis_host': redisConf.host})

  config: (app) ->
    obj = this
    @debug = 'production' != app.get('env')
    @storage = new storage.Storage({
      redis_client: @redisClient
      debug: @debug
    })

    show = @show
    search = @search
    app.get "#{@profile}/:id", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      show req, res, obj
    queryByIds = @queryByIds
    app.get "/#{@profile}/query", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      queryByIds req, res, obj
    app.get "/#{@profile}/search", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      search req, res, obj

    super(app)

  @getClient: (req, obj) ->
    baseUrl = obj.baseUrl
    version = global.cloudAPIs.version['project']
    service = openclient.getAPI "openstack", obj.service, version
    obj.client = new service(
      url: baseUrl
      scoped_token: req.session.token
      tenant: req.session.tenant.id
      debug: obj.debug
    )
    obj.client

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
    if not controllerBase.checkToken req, res
      return
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
      sort_field: 'fetch_at'
      limit: limit
      query: req.query
      debug: obj.debug
    , (err, projects) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        res.send projects

  show: (req, res, obj) ->
    if not controllerBase.checkToken req, res
      return
    obj.storage.getObject
      resource_type: 'projects'
      id: req.params.id
      debug: obj.debug
    , (err, project) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        res.send project

  create: (req, res, obj) ->
    if not controllerBase.checkToken req, res
      return
    params =
      data: req.body
    client = ProjectController.getClient req, obj
    client['projects'].create params, (err, data, status) ->
      if err
        logger.error err.message, err.status
        res.send err, err.status
      else
        try
          opts =
            hash_prefix: 'projects'
            data: data
          obj.storage.updateObject opts, (project) ->
            res.send data
        catch error
          logger.error "Error at update project", error
          res.send data
    return

  del: (req, res, obj) ->
    if not controllerBase.checkToken req, res
      return
    params =
      id: req.params.id
    client = ProjectController.getClient req, obj
    client['projects'].del params, (err, data) ->
      if err
        logger.error "Failed to delete #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        opts =
          hash_prefix: 'projects'
          object_id: req.params.id
        obj.storage.deleteObject opts, (project) ->
          res.send data, 200
    return

  update: (req, res, obj) ->
    if not controllerBase.checkToken req, res
      return
    params =
      data: req.body
      id: req.params.id
    client = ProjectController.getClient req, obj
    client['projects'].update params, (err, data) ->
      if err
        logger.error "Failed to update project as: ", err
        res.send err, obj._ERROR_400
      else
        args =
          id: req.params.id
        client['projects'].get args, (err, detail) ->
          if err
            res.send data
          else
            delete detail.links
            delete detail.domain_id
            opts =
              hash_prefix: 'projects'
              data: detail
            obj.storage.updateObject opts, (project) ->
              res.send detail
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
    obj.storage.getObjectsByKeyValues
      resource_type: 'projects'
      query_cons: query_cons
      require_detail: req.query.require_detail
      condition_relation: 'and'
      limit: limit
      debug: obj.debug
    , (err, projects) ->
      if err
        logger.error "Failed to get projects as: ", err
        res.send err, err.status
      else
        res.send projects

module.exports = ProjectController
