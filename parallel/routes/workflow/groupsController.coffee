# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # feedback controller.
###
class GroupController extends controllerBase

  constructor: () ->
    options =
      service: 'workflow'
      profile: 'option_groups'
    super(options)

module.exports = GroupController
