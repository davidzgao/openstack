# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class NodeController extends controllerBase

  constructor: () ->
    options =
      service: 'deployment'
      profile: 'deploy/node'
      alias: 'deployNodes'
    super(options)

module.exports = NodeController
