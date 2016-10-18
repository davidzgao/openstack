# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class SecurityGroupRuleController extends controllerBase

  constructor: () ->
    options =
      service: 'network'
      profile: 'security-group-rules'
      alias: 'security-group-rules'
    super(options)


module.exports = SecurityGroupRuleController
