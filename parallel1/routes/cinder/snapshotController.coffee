# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # quota controller.
###
class SnapshotController extends controllerBase

  constructor: () ->
    options =
      service: 'volume'
      profile: 'snapshots'
      adder: "cinder"
    super(options)

module.exports = SnapshotController
