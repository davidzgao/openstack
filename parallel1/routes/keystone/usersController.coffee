'use strict'

controllerBase = require('../controller').ControllerBase
openclient = require 'openclient'
redis = require('ecutils').redis
storage = require('ecutils').storage
crypto = require('crypto')


class UserController extends controllerBase

  constructor: () ->
    # The v3 API endpoint not in service catalog
    options =
      service: 'identity'
      profile: 'users'
      baseUrl: global.cloudAPIs.keystone.v3
    super(options)
    @redisClient = redis.connect({'redis_host': redisConf.host})

  config: (app) ->
    obj = @
    search = @search
    listProjects = @listProjects
    membership = @membership
    app.get "/#{@profile}/:id/projects", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      listProjects req, res, obj
    queryByIds = @queryByIds
    app.get "/#{@profile}/query", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      queryByIds req, res, obj
    app.get "/#{@profile}/search", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      search req, res, obj
    app.get "/#{@profile}/membership", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      membership req, res, obj

    @debug = 'production' != app.get('env')
    @storage = new storage.Storage({
      redis_client: @redisClient
      debug: @debug
    })
    super(app)

  @getClient: (req, obj, token, tenant_id) ->
    baseUrl = obj.baseUrl
    version = global.cloudAPIs.version[obj.service]
    service = openclient.getAPI "openstack", obj.service, version
    if req.session.tenant and req.session.token
      obj.client = new service(
        url: baseUrl
        scoped_token: req.session.token
        tenant: req.session.tenant.id
        debug: obj.debug
      )
    else
      obj.client = new service(
        url: baseUrl
        scoped_token: token
        tenant: tenant_id
        debug: true
      )
    return obj.client

  queryByIds: (req, res, obj) ->
    try
      options =
        'ids': JSON.parse req.query.ids
        'fields': JSON.parse req.query.fields
        'resource_type': 'users'
    catch err
      res.send err, controllerBase._ERROR_400
      return

    obj.storage.getObjectsByIds options, (err, replies) ->
      if err
        res.send err "Failed to get users."
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
      resource_type: 'users'
      query: req.query
      limit: limit
      debug: obj.debug
    , (err, users) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        res.send users

  show: (req, res, obj) ->
    obj.storage.getObject
      resource_type: 'users'
      id: req.params.id
    , (err, user) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        res.send user

  create: (req, res, obj) ->
    params =
      data: req.body
    client = UserController.getClient req, obj
    client[obj.alias].create params, (err, data) ->
      if err
        logger.error "Failed to create user: ", err
        res.send err, err.status
      else
        try
          opts =
            hash_prefix: 'users'
            data: data
          obj.storage.updateObject opts, (user) ->
            logger.debug "Update the users from redis."
            res.send data
        catch
          res.send data
    return

  del: (req, res, obj) ->
    params =
      id: req.params.id
    client = UserController.getClient req, obj
    client[obj.alias].del params, (err, data) ->
      if err
        logger.error "Failed to delete #{obj.alias} as: ", err
        res.send err, err.status
      else
        opts =
          hash_prefix: 'users'
          object_id: req.params.id
        obj.storage.deleteObject opts, (user) ->
          logger.debug "Delete the user from redis."
        res.send data
    return

  update_password: (options) ->
    client = UserController.getClient(options.req, options.obj,
    options.token, options.tenant_id)
    params =
      data:
        user:
          password: options.req.body.password
      id: options.req.body.userId
    client['users'].update_password params, (err, data) ->
      if options.callback
        options.callback options.res, err, data

  update: (req, res, obj) ->
    params =
      data:
        user: req.body
      id: req.params.id
    client = UserController.getClient req, obj
    if req.body.new_password and req.body.old_password
      params =
        data:
          user:
            password: req.body.new_password
        id: req.params.id

      sha1Hash = crypto.createHash("sha1")
      currentPass = req.body.old_password
      currentPassword = sha1Hash.update(currentPass).digest('hex')
      if req.session.password != currentPassword
        res.send "Current password error", 400
        return
      client[obj.alias].update_password params, (err, data) ->
        if err
          logger.error "Failed ot update password!"
          res.send err, err.status
        else
          res.send data
      return
    else
      client[obj.alias].update_user params, (err, data) ->
        if err
          logger.error "Failed ot update user info."
          res.send err, err.status
        else
          user = data.user
          user.tenantId = user.default_project_id
          delete user.default_project_id
          opts =
            hash_prefix: 'users'
            data: user
          obj.storage.updateObject opts, (user) ->
            res.send data
            logger.debug "Success to update user detail!"
        return

  listProjects: (req, res, obj) ->
    params =
      id: req.params.id
    client = UserController.getClient req, obj
    client[obj.alias].listProjects params, (err, data) ->
      if err
        logger.error "Failed to get projects of user belongs."
        res.send err, err.status
      else
        res.send data

  membership: (req, res, obj) ->
    obj.storage.getObjects
      resource_type: 'projects_user_belongs_to'
    , (err, data) ->
      if err
        logger.error "Failed to get projects of user belongs."
        res.send err, err.status
      else
        res.send data

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
    if req.query.tenantId
      query_cons['tenant_id'] = req.query.tenantId
    obj.storage.getObjectsByKeyValues
      resource_type: 'users'
      query_cons: query_cons
      require_detail: req.query.require_detail
      condition_relation: 'and'
      debug: obj.debug
    , (err, users) ->
      if err
        logger.error "Failed to get users as: ", err
        res.send err, err.status
      else
        res.send users

module.exports = UserController
