# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # workflow type controller.
###
class AppController extends controllerBase

  constructor: () ->
    options =
      service: 'workflow'
      profile: 'apps'
    super(options)

  config: (app) ->
    obj = @
    image = @image
    app.get "/#{@profile}/:id/image", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      image req, res, obj

    super(app)

  image: (req, res, obj) ->
    params =
      id: req.params.id
      res: "/#{req.params.id}/image"
    client = controllerBase.getClient req, obj
    client[obj.alias].getImage params, (err, data) ->
      if err
        logger.error "Failed to get app image."
      else
        res.send data
    return

module.exports = AppController
