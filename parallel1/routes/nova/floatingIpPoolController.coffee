# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class FloatingIpPoolController extends controllerBase

  constructor: () ->
    options =
      service: 'compute'
      profile: 'os-floating-ip-pools'
      alias: 'floating_ip_pools'
    super(options)


module.exports = FloatingIpPoolController
