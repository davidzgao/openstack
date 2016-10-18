# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class ClusterController extends controllerBase

  constructor: () ->
    options =
      service: 'compute'
      profile: 'os-aggregates'
      alias: 'clusters'
    super(options)

  config: (app) ->
    obj = @
    action = @action
    app.post "/#{@profile}/:id/action", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      action req, res, obj

    super(app)

  action: (req, res, obj) ->
    client = controllerBase.getClient req, obj
    params = {
      id: req.params.id
      data: req.body
    }
    client[obj.alias]['action'] params, (err, data, status) ->
      if err
        res.send err, status
      else
        res.send data, status

module.exports = ClusterController
