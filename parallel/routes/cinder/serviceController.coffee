# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class ServiceController extends controllerBase

  constructor: () ->
    options =
      service: 'volume'
      profile: 'os-services'
      alias: 'services'
      adder: 'cinder'
    super(options)

  config: (app) ->
    obj = @
    action = @action
    enableService = @enableService
    disableService = @disableService
    app.put "/#{@adder}/#{@profile}/enable", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      enableService req, res, obj
    app.put "/#{@adder}/#{@profile}/disable", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      disableService req, res, obj

    super(app)

  enableService: (req, res, obj) ->
    client = controllerBase.getClient req, obj
    params =
      data: req.body
    client[obj.alias].enable params, (err, data, status) ->
      if err
        res.send err, status
      else
        res.send data, status

  disableService: (req, res, obj) ->
    client = controllerBase.getClient req, obj
    params =
      data: req.body
    client[obj.alias].disable params, (err, data, status) ->
      if err
        res.send err, status
      else
        res.send data, status

module.exports = ServiceController
