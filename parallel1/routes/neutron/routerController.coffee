'use strict'

controllerBase = require('../controller').ControllerBase

class RouterController extends controllerBase

  constructor: () ->
    options =
      service: 'network'
      profile: 'routers'
      alias: 'routers'
    super(options)

  config: (app) ->
    obj = @
    addInterface = @addInterface
    removeInterface = @removeInterface
    app.put "/#{@profile}/:id/add_router_interface", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      addInterface req, res, obj
    app.put "/#{@profile}/:id/remove_router_interface", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      removeInterface req, res, obj

    super(app)

  addInterface: (req, res, obj) ->
    client = controllerBase.getClient req, obj
    params =
      data: req.body
      id: req.params.id
    client[obj.alias].addInterface params, (err, data, status) ->
      if err
        res.send err, err.status
      else
        res.send data

  removeInterface: (req, res, obj) ->
    client = controllerBase.getClient req, obj
    params =
      data: req.body
      id: req.params.id
    client[obj.alias].removeInterface params, (err, data, status) ->
      if err
        res.send err, err.status
      else
        res.send data

module.exports = RouterController
