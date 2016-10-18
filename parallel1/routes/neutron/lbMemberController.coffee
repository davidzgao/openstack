'use strict'

controllerBase = require('../controller').ControllerBase

class MemberController extends controllerBase

  constructor: () ->
    options =
      service: 'network'
      profile: 'lb/members'
      alias: 'members'
    super(options)

module.exports = MemberController
