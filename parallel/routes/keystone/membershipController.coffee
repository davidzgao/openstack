'use strict'

controllerBase = require('../controller').ControllerBase
redis = require('ecutils').redis
storage = require('ecutils').storage
openclient = require 'openclient'

###
# The V2 API for keystone projects(tenants).
# For hidden the confusion for project and tenant,
# replace the tenants of projects and the projectV3
# stand for V3 projects API.
###
class MembershipController extends controllerBase

  constructor: () ->
    options =
      service: 'identity'
      profile: 'membership'
    super(options)
    @redisClient = redis.connect(
      'redis_host': redisConf.host
      'redis_password': redisConf.pass
      'redis_port': redisConf.port)

  config: (app) ->
    obj = this
    create = @create
    del = @del
    @debug = 'production' != app.get('env')
    app.post "/#{@profile}/:id", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      create req, res, obj
    app.del "/#{@profile}/:id/:user", (req, res) ->
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

  show: (req, res, obj) ->
    params =
      data:
        project: req.params.id
    client = controllerBase.getClient req, obj, true
    client['membership'].all params, (err, data) ->
      if err
        logger.error "Failed to get membership of tenant:", req.params.id
        res.send err, obj._ERROR_400
      else
        res.send(data)
    return

  create: (req, res, obj) ->
    params =
      endpoint_type: 'identity'
      data:
        project: req.params.id
        user: req.body.user
        id: req.body.role
    client = controllerBase.getClient req, obj, true
    client['membership'].create params, (err, data) ->
      if err
        logger.error "Failed add user for project: ", req.params.id
        res.send err, obj._ERROR_400
      else
        param = {
          id: req.body.user
        }
        obj.baseUrl = global.cloudAPIs.keystone.v3
        v3client = MembershipController.getClient req, obj
        v3client['users'].listProjects param, (error, projects) ->
          obj.storage.getObject
            resource_type: 'projects_user_belongs_to'
            id: req.body.user
          , (err, belongs) ->
            if belongs
              belongs.projects = projects.projects
              obj.storage.updateObject
                hash_prefix: 'projects_user_belongs_to'
                data: belongs
                fetch_at: belongs.fetch_at
                need_fresh: true
              , (err, reply) ->
                if err
                  logger.error "Error at update hash for projects_user_belongs_to"
        res.send(data)

  del: (req, res, obj) ->
    params =
      endpoint_type: 'identity'
      id: req.params.user
      data:
        project: req.params.id
    client = controllerBase.getClient req, obj, true
    client['membership'].del params, (err, data, status) ->
      if err
        logger.error "Failed remove user for project: ", req.params.id
        res.send err, status
      else
        obj.storage.getObject
          resource_type: 'projects_user_belongs_to'
          id: req.params.user
        , (err, belongs) ->
          if belongs
            if belongs.projects
              newProjects = []
              projects = JSON.parse(belongs.projects)
              for project in projects
                if project.id == req.params.id
                  continue
                else
                  newProjects.push project
              belongs.projects = newProjects
              obj.storage.updateObject
                hash_prefix: 'projects_user_belongs_to'
                data: belongs
                fetch_at: belongs.fetch_at
                need_fresh: true
              , (err, reply) ->
                if err
                  logger.error "Error at update hash for projects_user_belongs_to"

        logger.debug "Success remove user for project: ", req.params.id
        res.send data, status.status

module.exports = MembershipController
