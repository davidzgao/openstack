# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase
async = require('async')
redis = require('ecutils').redis
storage = require('ecutils').storage

###*
 # server controller.
###
class TenantUsageController extends controllerBase

  constructor: () ->
    options =
      service: 'compute'
      profile: 'os-simple-tenant-usage'
      alias: 'usage'
    super(options)
    @redisClient = redis.connect({'redis_host': redisConf.host})

  config: (app) ->
    obj = @
    reportAll = @reportAll
    app.get "/#{@profile}/download", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      reportAll req, res, obj

    @debug = 'production' != app.get('env')
    @storage = new storage.Storage({
      redis_client: @redisClient
      debug: @debug
    })

    super(app)

  reportAll: (req, res, obj) ->
    params = {query: {}}
    for query of req.query
      if query == '_' or query == '_cache'
        continue
      params.query[query] = req.query[query]

    client = controllerBase.getClient req, obj

    usageCallback = (results, res, err) ->
      _ = i18n.__
      reportNote = {
        project: _("Project Name")
        projectId: _("Project ID")
        cpuTotal: _("CPU Hours")
        memUsage: _("RAM Hours(GB*Hour)")
        diskUsage: _("Disk Hours(GB*Hour)")
        totalUsage: _("Instances Uptime(Hour)")
        instanceName: _("Instance Name")
        ramGB: _("RAM (GB)")
        diskGB: _("Disk (GB)")
        upTime: _("Uptime (Hour)")
      }
      obj.storage.getObjects
        resource_type: 'projects'
        query: {}
        debug: obj.debug
      , (err, projects) ->
        projectsMap = {}
        serverUsages = {}
        if err
          logger.error "Failed to get projects at generate usage report!"
        else
          for project in projects.data
            projectsMap[project.id] = project.name
          for usage in results
            usage.project_name = projectsMap[usage.tenant_id]
            if usage.total_vcpus_usage > 1
              usage.cpuUsage = usage.total_vcpus_usage.toFixed(2)
            else
              usage.cpuUsage = 0
            if usage.total_memory_mb_usage > 1
              convertGB = usage.total_memory_mb_usage / 1024
              usage.memUsage = convertGB.toFixed(2)
            else
              usage.memUsage = 0
            if usage.total_local_gb_usage > 1
              usage.diskUsage = usage.total_local_gb_usage.toFixed(2)
            else
              usage.diskUsage = 0
            if usage.total_hours > 1
              usage.totalHours = usage.total_hours.toFixed(2)
            else
              usage.totalHours = 0
            serverUsages[usage.tenant_id] = usage.server_usages
          res.render 'usage', {
            usage: results
            note: reportNote
            serverUsages: serverUsages
          }

    usageGet = (options, callback) ->
      projectParams =
        id: options.tenant_id
        query: params.query
      client[obj.alias].get projectParams, (err, usage) ->
        if err
          callback err, []
        else
          callback null, usage

    client[obj.alias].all params, (err, data) ->
      if err
        logger.error "Failed to get tenant usage."
        res.send err, obj._ERROR_400
      else
        async.map(data, usageGet, (err, results) ->
          usageCallback results, res, err
        )

module.exports = TenantUsageController
