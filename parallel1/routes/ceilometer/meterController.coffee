'use strict'

controllerBase = require('../controller').ControllerBase

class MeterController extends controllerBase
  constructor: () ->
    options =
      service: 'metering'
      profile: 'meters'
      alias: 'meter'
    super(options)

  config: (app) ->
    obj = @
    show = @show
    @debug = 'production' != app.get('env')
    app.get "/#{@profile}/:item", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      show req, res, obj

  show: (req, res, obj) ->
    item = req.params.item
    query = req.query
    params =
      item: item
      query: query
    client = controllerBase.getClient req, obj
    client[obj.alias].getMeters params, (err, data) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        res.send data

module.exports = MeterController
