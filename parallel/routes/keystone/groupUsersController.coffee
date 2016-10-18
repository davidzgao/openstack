'use strict'

controllerBase = require('../controller').ControllerBase
redis = require('ecutils').redis
storage = require('ecutils').storage
openclient = require('openclient')
async = require('async')


class GroupUsersController extends controllerBase

  constructor: () ->
    options =
      service: 'identity'
      profile: 'group_users'
      baseUrl: global.cloudAPIs.keystone.v3
    super(options)
    @redisClient = redis.connect(
      'redis_host': redisConf.host
      'redis_password': redisConf.pass
      'redis_port': redisConf.port
    )

  config: (app) ->
    obj = @
    create = @create
    del = @del
    index = @index
    @debug = 'production' != app.get('env')
    app.get "/:groupId/#{@profile}", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      index req, res, obj
    app.post "/:groupId/#{@profile}/:userId", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      create req, res, obj
    app.del "/:groupId/#{@profile}/:userId", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      del req, res, obj
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

  @syncRedis: (req, obj, client, callback) ->
    try
      async.parallel([
        (cb) ->
          client['group_users'].all(
            endpoint_type: 'identity'
            data:
              group: req.params.groupId
            success: (users) ->
              cb(null, users)
            error: (error) ->
              cb(error, null)
          )
          return
        (cb) ->
          client['user_groups'].all(
            endpoint_type: 'identity'
            data:
              user: req.params.userId
            success: (groups) ->
              cb(null, groups)
            error: (error) ->
              cb(error, null)
          )
          return
      ], (err, results) ->
          group_users_relation = [{
            id: req.params.groupId
            users: results[0]
          }]
          userOpts =
            data: group_users_relation
            fetch_at: new Date().getTime()
            hash_prefix: 'group_users'
          user_groups_relation = [{
            id: req.params.userId
            groups: results[1]
          }]
          groupOpts =
            data: user_groups_relation
            fetch_at: new Date().getTime()
            hash_prefix: 'user_groups'
          async.series [
            (cb) ->
              obj.storage.updateObjects userOpts, (err, groupUsers) ->
                logger.debug "Update the group_users for redis."
                cb(err, groupUsers)
              return
            (cb) ->
              obj.storage.updateObjects groupOpts, (err, groupUsers) ->
                logger.debug "Update the user_groups for redis."
                cb(err, groupUsers)
              return
          ], (err) ->
            logger.error "Failed to update group_users or user_groups memberships into redis!"
      )
      callback()
    catch
      callback()

  index: (req, res, obj) ->
    params =
      data:
        group: req.params.groupId
    client = GroupUsersController.getClient req, obj, true
    client['group_users'].all params, (err, data) ->
      if err
        logger.error "Failed to get users for group: ", req.params.groupId
        res.send err, err.status
      else
        res.send data

  create: (req, res, obj) ->
    params =
      data:
        group: req.params.groupId
        user: req.params.userId
    client = GroupUsersController.getClient req, obj, true
    client['group_users'].create params, (err, data) ->
      if err
        logger.error "Failed to add user for group: ", req.params.groupId
        res.send err, obj._ERROR_400
      else
        GroupUsersController.syncRedis req, obj, client, () ->
          res.send data
    return

  del: (req, res, obj) ->
    params =
      endpoint_type: 'identity'
      data:
        group: req.params.groupId
        user: req.params.userId
    client = GroupUsersController.getClient req, obj, true
    client[obj.profile].del params, (err, data) ->
      if err
        logger.error "Failed to remove user for group: ", req.params.groupId
        res.send err, err.status
      else
        GroupUsersController.syncRedis req, obj, client, () ->
          res.send data
    return

module.exports = GroupUsersController
