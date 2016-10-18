'use strict'

controllerBase = require('../controller').ControllerBase
openclient = require('openclient')
redis = require('ecutils').redis
storage = require('ecutils').storage
crypto = require('crypto')


class GroupController extends controllerBase

  constructor: () ->
    options =
      service: 'identity'
      profile: 'groups'
      baseUrl: global.cloudAPIs.keystone.v3
    super(options)
    @redisClient = redis.connect({'redis_host': redisConf.host})

  config: (app) ->
    obj = @
    search = @search
    @debug = 'production' != app.get('env')
    @storage = new storage.Storage({
      redis_client: @redisClient
      debug: @debug
    })
    super(app)

  @getClient: (req, obj, token, tenant_id) ->
    baseUrl = obj.baseUrl
    version = global.cloudAPIs.version[obj.service]
    service = openclient.getAPI "openstack", obj.service, "3.0"
    if req.session.tenant and req.session.token
      obj.client = new service(
        url: baseUrl,
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
      resource_type: 'groups'
      limit: limit
      debug: obj.debug
    , (err, groups) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        res.send groups

  create: (req, res, obj) ->
    params =
      data: req.body
    client = GroupController.getClient req, obj
    client[obj.alias].create params, (err, data) ->
      if err
        logger.error "Failed to create group: ", err
        res.send err, err.status
      else
        try
          opts =
            hash_prefix: 'groups'
            data: data
          obj.storage.updateObject opts, (groups) ->
            logger.debug "Update the groups from redis."
            res.send data
        catch
          res.send data
    return

  del: (req, res, obj) ->
    params =
      id: req.params.id
    client = GroupController.getClient req, obj
    client[obj.alias].del params, (err, data) ->
      if err
        logger.error "Failed to delete #{obj.alias} as: ", err
        res.send err, err.status
      else
        opts =
          hash_prefix: 'groups'
          object_id: req.params.id
        obj.storage.deleteObject opts, (user) ->
          logger.debug "Delete the group from redis."
          res.send data
    return

  update: (req, res, obj) ->
    params =
      data:
        group: req.body
      id: req.params.id
    client = GroupController.getClient req, obj
    client[obj.alias].update params, (err, data) ->
      if err
        logger.error "Failed to update group info."
        res.send err, err.status
      else
        group = data.group
        opts =
          hash_prefix: 'groups'
          data: group
        obj.storage.updateObject opts, (group) ->
          res.send data
          logger.debug "Success to update user detal!"
    return

module.exports = GroupController
