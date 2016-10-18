# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase
redis = require('ecutils').redis
storage = require('ecutils').storage

###*
 # workflow controller.
###
class WorkflowController extends controllerBase

  constructor: () ->
    options =
      service: 'workflow'
      profile: 'workflow-requests'
    super(options)
    @redisClient = redis.connect(
      'redis_host': redisConf.host
      'redis_password': redisConf.pass
      'redis_port': redisConf.port
    )

  config: (app) ->
    obj = @
    approve = @approve
    edit = @edit
    resourceCheck = @resourceCheck
    app.get "/#{@profile}/:id/edit", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      edit req, res, obj
    app.put "/#{@profile}/:id", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      approve req, res, obj
    app.post "/resource_check", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      resourceCheck req, res, obj
    @debug = 'production' != app.get('env')
    @storage = new storage.Storage({
      redis_client: @redisClient
      debug: @debug
    })
    super(app)

  approve: (req, res, obj) ->
    imageId = undefined
    imagePass = undefined
    if req.body.content
      imageId = req.body.content.image
    if imageId
      obj.storage.getObject
        resource_type: 'images'
        id: imageId
      , (err, image) ->
        if err
          logger.error "Failed to get image"
        else
          if image
            imageMeta = JSON.parse(image.properties)
            imagePass = imageMeta.password
          else
            imagePass = undefined
        if imagePass
          req.body.content.admin_pass = imagePass
          params =
            data: req.body
            id: req.params.id
          client = controllerBase.getClient req, obj
          client[obj.alias].update params, (err, data) ->
            res.send(data)
        else
          params =
            data: req.body
            id: req.params.id
          client = controllerBase.getClient req, obj
          client[obj.alias].update params, (err, data) ->
            res.send(data)
    else
      params =
        data: req.body
        id: req.params.id
      client = controllerBase.getClient req, obj
      client[obj.alias].update params, (err, data) ->
        res.send(data)
    return

  edit: (req, res, obj) ->
    params =
      id: req.params.id
    client = controllerBase.getClient req, obj
    client[obj.alias].edit params, (err, data) ->
      if err
        res.send err, err.status
      else
        res.send data
      return

  resourceCheck: (req, res, obj) ->
    params = {
      data: req.body
    }
    client = controllerBase.getClient req, obj
    client[obj.alias].resourceCheck params, (err, data) ->
      if err
        res.send err, err.status
      else
        res.send data
      return

module.exports = WorkflowController
