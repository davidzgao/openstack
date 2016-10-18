'use strict'

controllerBase = require('../controller').ControllerBase

class FloatingIPController extends controllerBase

  constructor: () ->
    options =
      service: 'network'
      profile: 'floatingips'
      alias: 'floatingips'
    super(options)

module.exports = FloatingIPController
