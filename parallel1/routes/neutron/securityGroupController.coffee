# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class SecurityGroupController extends controllerBase

  constructor: () ->
    options =
      service: 'network'
      profile: 'security-groups'
      alias: 'security-groups'
    super(options)


module.exports = SecurityGroupController
