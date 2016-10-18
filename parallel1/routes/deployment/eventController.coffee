# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class EventController extends controllerBase

  constructor: () ->
    options =
      service: 'deployment'
      profile: 'deploy/event'
      alias: 'deployEvents'
    super(options)

  create: (req, res, obj) ->
    params =
      project: req.session.tenant.id
      data: req.body
    client = controllerBase.getClient req, obj
    client[obj.alias].create params, (err, data)->
      if err
        logger.error "Failed to create #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        res.send data
    return


module.exports = EventController
