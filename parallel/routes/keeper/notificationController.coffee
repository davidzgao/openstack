# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class NotificationController extends controllerBase

  constructor: () ->
    options =
      service: 'keeper'
      profile: 'messages'
    super(options)

  config: (app) ->
    obj = @
    updateRead = @updateRead
    app.put "/#{@profile}/update/all", (req, res) ->
      if not controllerBase.checkToken req, res
        return
      updateRead req, res, obj
    super(app)

  updateRead: (req, res, obj) ->
    params =
      data: req.body
    client = controllerBase.getClient req, obj
    client[obj.alias]['update_read'] params, (err, data) ->
      if err
        logger.error "Failed to update #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        res.send(data)
    return


module.exports = NotificationController
