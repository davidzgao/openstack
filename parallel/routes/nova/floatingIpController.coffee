# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class FloatingIpController extends controllerBase

  constructor: () ->
    options =
      service: 'compute'
      profile: 'os-floating-ips'
      alias: 'floating_ips'
    super(options)


module.exports = FloatingIpController
