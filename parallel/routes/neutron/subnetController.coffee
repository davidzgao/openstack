'use strict'

controllerBase = require('../controller').ControllerBase

class SubnetController extends controllerBase

  constructor: () ->
    options =
      service: 'network'
      profile: 'subnets'
      alias: 'subnets'
    super(options)

module.exports = SubnetController
