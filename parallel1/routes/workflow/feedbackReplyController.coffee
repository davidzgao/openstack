# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # feedback controller.
###
class FeedbackReplyController extends controllerBase

  constructor: () ->
    options =
      service: 'workflow'
      profile: 'feedback_replies'
    super(options)

module.exports = FeedbackReplyController
