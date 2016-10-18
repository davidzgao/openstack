'use strict'

controllerBase = require('../controller').ControllerBase

class HealthMonitorController extends controllerBase

  constructor: () ->
    options =
      service: 'network'
      profile: 'lb/health_monitors'
      alias: 'health_monitors'
    super(options)

module.exports = HealthMonitorController
