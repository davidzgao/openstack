# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class RuleController extends controllerBase

  constructor: () ->
    options =
      service: 'maintenance'
      profile: 'rules'
    super(options)

  config: (app) ->
    obj = @
    template = @template
    app.get "/#{@profile}/:id/template", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      template req, res, obj

    super(app)

  template: (req, res, obj) ->
    params =
      data: {}
      id: req.params.id
    client = controllerBase.getClient req, obj
    client[obj.alias].template params, (err, data) ->
      if err
        res.send err, obj._ERROR_400
      else
        res.send data
    return


module.exports = RuleController
