# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class FloatingIpBulkController extends controllerBase

  constructor: () ->
    options =
      service: 'compute'
      profile: 'os-floating-ips-bulk'
      alias: 'floating_ip_info'
    super(options)


module.exports = FloatingIpBulkController
