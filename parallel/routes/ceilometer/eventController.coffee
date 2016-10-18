'use strict'

controllerBase = require("../controller").ControllerBase

class EventController extends controllerBase
  constructor: () ->
    options =
      service: 'metering'
      profile: 'events'
      alias: 'event'
    super(options)


  config: (app) ->
    obj = @
    show = @show
    @debug = 'production' != app.get('env')
    app.get "/#{@profile}", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      show req, res, obj


  show: (req, res, obj) ->
    query = req.query
    params =
      query:query
    client = controllerBase.getClient req, obj
    client[obj.alias].getEvents params, (err, data) ->
      if err
        logger.error "Failed to get #{obj.alias} as:", err
        res.send err, controllerBase._ERROR_400
      else
        res.send data

module.exports = EventController
