'use strict'

controllerBase = require('../controller').ControllerBase

class VipController extends controllerBase

  constructor: () ->
    options =
      service: 'network'
      profile: 'lb/vips'
      alias: 'vips'
    super(options)

module.exports = VipController
