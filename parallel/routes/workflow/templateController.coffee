# Copyright (c) 2015. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase
redis = require('ecutils').redis
storage = require('ecutils').storage

###*
 # template controller.
###
class TemplateController extends controllerBase

  constructor: () ->
    options =
      service: 'workflow'
      profile: 'load_template'
    super(options)

  config: (app) ->
    obj = @
    load = @load
    app.get "/load_template/:id", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      load req, res, obj
    @debug = 'production' != app.get('env')
    super(app)

  load: (req, res, obj) ->
    params =
      id: req.params.id

    client = controllerBase.getClient req, obj
    client[obj.alias].load_template params, (err, data) ->
      if err
        res.send err, err.status
      else
        res.send data
    return

module.exports = TemplateController
