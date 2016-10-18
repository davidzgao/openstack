'use strict'

controllerBase = require('../controller').ControllerBase

class PriceController extends controllerBase

  constructor: () ->
    options =
      service: 'price'
      profile: 'prices'
    super(options)

module.exports = PriceController
