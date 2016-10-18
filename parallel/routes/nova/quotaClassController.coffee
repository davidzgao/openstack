# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # quota controller.
###
class QuotaClassController extends controllerBase

  constructor: () ->
    options =
      service: 'compute'
      profile: 'os-quota-class-sets'
      alias: 'quota_class'
      adder: "nova"
    super(options)
  # add interface update for v2
  config: (app) ->
    obj = this
    super(app)
    profile = "/#{@profile}"
    if @adder
      profile = "/#{@adder}/#{@profile}"
    update = @updateQuota
    app.put "#{profile}/:id/defaults", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      update req, res, obj

  updateQuota: (req, res, obj) ->
    params =
      data: req.body
      id: req.params.id
    client = controllerBase.getClient req, obj
    client[obj.alias].update params, (err, data) ->
      if err
        logger.error "Failed to update #{obj.alias} as: " , err
        res.send err,obj._ERROR_400
      else
        res.send(data)
    return

module.exports = QuotaClassController
