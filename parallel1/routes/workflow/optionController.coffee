# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # feedback controller.
###
class OptionController extends controllerBase

  constructor: () ->
    options =
      service: 'workflow'
      profile: 'options'
    super(options)

  update: (req, res, obj) ->
    params =
      data: req.body
      id: req.params.id
    client = controllerBase.getClient req, obj
    client[obj.alias].update params, (err, data) ->
      if err
        logger.error "Failed to update #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        confInfo = data.option
        switch confInfo.key
          when 'smtp_server' then\
          global.emailConf.smtp_server = confInfo.value
          when 'email_sender' then\
          global.emailConf.sender = confInfo.value
          when 'email_sender_password' then\
          global.emailConf.password = confInfo.value
          when 'email_sender_name' then\
          global.emailConf.sender_name = confInfo.value
          when 'site_name' then\
          global.emailConf.site_display_name = confInfo.value
          else break
        global.transport = undefined
        res.send(data)
    return

module.exports = OptionController
