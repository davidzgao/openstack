# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class VolumeTypeController extends controllerBase

  constructor: () ->
    options =
      service: 'volume'
      profile: 'volume_types'
      alias: 'types'
    super(options)

module.exports = VolumeTypeController
