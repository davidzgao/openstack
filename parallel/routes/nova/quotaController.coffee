# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # quota controller.
###
class QuotaController extends controllerBase

  constructor: () ->
    options =
      service: 'compute'
      profile: 'os-quota-sets'
      alias: 'quotas'
      adder: "nova"
    super(options)
  # add interface detail for v2
  config: (app) ->
    obj = this
    super(app)
    profile = "/#{@profile}"
    if @adder
      profile = "/#{@adder}/#{@profile}"
    detail = @detailQuota
    app.get "#{profile}/:id/defaults", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      detail req, res, obj
    updateDefault = @update
    app.put "#{profile}/:id/defaults", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      updateDefault req, res, obj

  detailQuota: (req, res, obj) ->
    id = req.params.id
    params =
      id: id
      query: {}
    for query of req.query
      # skip _, _cache query.
      if query == '_' or query == '_cache'
        continue
      params.query[query] = req.query[query]
    client = controllerBase.getClient req, obj
    client[obj.alias].defaults params, (err, data) ->
      if err
        logger.error "Failed to get #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        res.send data
    return

module.exports = QuotaController
