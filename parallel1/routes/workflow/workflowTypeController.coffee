# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # workflow type controller.
###
class WorkflowTypeController extends controllerBase

  constructor: () ->
    options =
      service: 'workflow'
      profile: 'workflow-request-types'
    super(options)

module.exports = WorkflowTypeController
