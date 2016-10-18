# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class HypervisorController extends controllerBase

  constructor: () ->
    options =
      service: 'compute'
      profile: 'os-hypervisors'
      alias: 'hypervisors'
    super(options)

  config: (app) ->
    obj = @
    index = @index
    show = @show
    update = @update
    del = @del
    create = @create
    statistic = @statistic
    @debug = 'production' != app.get('env')
    app.get "/#{@profile}/statistics", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      statistic req, res, obj
    app.get "/#{@profile}", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      index req, res, obj
    app.get "/#{@profile}/detail", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      index req, res, obj, detail=true
    app.get "/#{@profile}/:id", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      show req, res, obj
    app.put "/#{@profile}/:id", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      update req, res, obj
    app.post "/#{@profile}", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      create req, res, obj
    app.del "/#{@profile}/:id", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      del req, res, obj
    return

  statistic: (req, res, obj) ->
    client = controllerBase.getClient req, obj
    client[obj.alias].statistic {}, (err, stats) ->
      if err
        logger.error "Failed to get #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        res.send stats.hypervisor_statistics
    return


module.exports = HypervisorController
