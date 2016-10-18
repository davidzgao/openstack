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
      service: 'compute'
      profile: 'os-security-group-rules'
      alias: 'security_group_rules'
    super(options)


module.exports = SecurityGroupRuleController
