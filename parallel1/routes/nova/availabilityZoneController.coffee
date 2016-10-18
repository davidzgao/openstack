# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class AvailabilityZoneController extends controllerBase

  constructor: () ->
    options =
      service: 'compute'
      profile: 'os-availability-zone'
      alias: 'availability_zones'
    super(options)


module.exports = AvailabilityZoneController
