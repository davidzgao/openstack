'use strict'

controllerBase = require('../controller').ControllerBase

class PoolController extends controllerBase

  constructor: () ->
    options =
      service: 'network'
      profile: 'lb/pools'
      alias: 'pools'
    super(options)

  config: (app) ->
    obj = @
    assginMonitor = @assginMonitor
    app.post "/lb/pools/:id/health_monitors", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      assginMonitor req, res, obj
    super(app)

  assginMonitor: (req, res, obj) ->
    params =
      id: req.params.id
      data: req.body
    client = controllerBase.getClient req, obj
    console.log client
    client[obj.alias].assginHealthMonitor params, (err, data) ->
      if err
        res.send err, err.status
      else
        res.send data
    return

module.exports = PoolController
