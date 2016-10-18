# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class NetworkController extends controllerBase

  constructor: () ->
    options =
      service: 'compute'
      profile: 'os-networks'
      alias: 'os-networks'
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
    params =
      id: req.params.id
    client = controllerBase.getClient req, obj
    client[obj.alias].disassociate params, (err, data) ->
      if err
        res.send err
      else
        res.send data

module.exports = NetworkController
