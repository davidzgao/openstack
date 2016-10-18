'use strict'

controllerBase = require('../controller').ControllerBase
roleController = require('./rolesController')
redis = require('ecutils').redis
storage = require('ecutils').storage
openclient = require('openclient')
async = require('async')


class ProjectGroupsController extends controllerBase

  constructor: () ->
    options =
      service: 'identity'
      profile: 'project_groups'
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
    app.get "/:projectId/#{@profile}", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      index req, res, obj
    app.post "/:projectId/#{@profile}/:groupId", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      create req, res, obj
    app.del "/:projectId/#{@profile}/:groupId", (req, res) ->
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
      client['groups'].all
        endpoint_type: 'identity'
        success: (allGroups) ->
          async.parallel [
            (cb) ->
              client['group_project_memberships'].all
                endpoint_type: 'identity'
                data:
                  group: req.params.groupId
                success: (projects) ->
                  cb(null, projects)
                error: (error) ->
                  cb(error, null)
              return
            (cb) ->
              groups = []
              async.each allGroups, (grp, internalCallback) ->
                client['project_group_memberships'].all
                  endpoint_type: 'identity'
                  data:
                    project: req.params.projectId
                    group: grp.id
                  success: (memberships) ->
                    for mem in memberships
                      groups.push {id: mem.id}
                    internalCallback()
                  error: (error) ->
                    internalCallback(error, null)
                return
              , (err) ->
                cb(err, groups)
              return
          ], (err, results) ->
            group_project_relation = [{
              id: req.params.groupId
              group_projects: results[0]
            }]
            projectOpts =
              data: group_project_relation
              fetch_at: new Date().getTime()
              hash_prefix: 'group_projects'
            project_group_relation = [{
              id: req.params.projectId
              project_groups: results[1]
            }]
            groupOpts =
              data: project_group_relation
              fetch_at: new Date().getTime()
              hash_prefix: 'project_groups'
            async.series [
              (cb) ->
                obj.storage.updateObjects projectOpts, (err, projects) ->
                  logger.debug "Update the group_projects for redis."
                  cb(err, projects)
                return
              (cb) ->
                obj.storage.updateObjects groupOpts, (err, groups) ->
                  logger.debug "Update the project_groups for redis."
                  cb(err, groups)
                return
            ], (err, results) ->
              if err
                logger.error "Failed to update group_projects or project_groups memberships into redis!"
          callback()
        error: (error) ->
          callback(error)
    catch err
      logger.error "Failed to update group_projects or project_groups memberships into redis!"
      callback(err)

  index: (req, res, obj) ->
    client = ProjectGroupsController.getClient req, obj, true
    client['groups'].all
      endpoint_type: 'identity'
      success: (allGroups) ->
        groups = []
        async.each allGroups, (grp, internalCallback) ->
          client['project_group_memberships'].all
            endpoint_type: 'identity'
            data:
              project: req.params.projectId
              group: grp.id
            success: (memberships) ->
              for mem in memberships
                groups.push {id: mem.id, name: mem.name}
              internalCallback()
            error: (error) ->
              internalCallback(error, null)
          return
        , (err) ->
          if err
            res.send err, 500
          else
            res.send groups
        return
      error: (error) ->
        res.send error, 500

  create: (req, res, obj) ->
    roleCtrl = new roleController()
    roleClient = controllerBase.getClient req, roleCtrl, true
    roleClient['roles'].all {}, (err, roles) ->
      for role in roles
        if role['name'] == 'Member'
          memberId = role['id']
          params =
            data:
              id: memberId
              group: req.params.groupId
              project: req.params.projectId
          client = ProjectGroupsController.getClient req, obj, true
          client['project_group_memberships'].create params, (err, data) ->
            if err
              logger.error "Failed to add group to project: ", req.params.projectId
              res.send err, err.status
            else
              ProjectGroupsController.syncRedis req, obj, client, (err) ->
                if err
                  res.send err, 500
                else
                  res.send data
          return

  del: (req, res, obj) ->
    params =
      id: req.params.groupId
      data:
        project: req.params.projectId
    client = ProjectGroupsController.getClient req, obj
    client['project_group_memberships'].del params, (err, data) ->
      if err
        logger.error "Failed to remove group from project: ", req.params.projectId
        res.send err, err.status
      else
        ProjectGroupsController.syncRedis req, obj, client, () ->
          res.send data
    return

module.exports = ProjectGroupsController
