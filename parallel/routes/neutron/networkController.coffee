'use strict'

controllerBase = require('../controller').ControllerBase

class NetworkController extends controllerBase

  constructor: () ->
    options =
      service: 'network'
      profile: 'networks'
      alias: 'networks'
    super(options)

module.exports = NetworkController
