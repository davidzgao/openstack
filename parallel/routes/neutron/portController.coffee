'use strict'

controllerBase = require('../controller').ControllerBase

class PortController extends controllerBase

  constructor: () ->
    options =
      service: 'network'
      profile: 'ports'
      alias: 'ports'
    super(options)

module.exports = PortController
