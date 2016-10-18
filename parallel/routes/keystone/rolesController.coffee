'use strict'

controllerBase = require('../controller').ControllerBase


###
# The V2 API for keystone projects(tenants).
# For hidden the confusion for project and tenant,
# replace the tenants of projects and the projectV3
# stand for V3 projects API.
###
class RoleController extends controllerBase

  constructor: () ->
    options =
      service: 'identity'
      profile: 'roles'
    super(options)

  config: (app) ->
    obj = this
    @debug = 'production' != app.get('env')

    super(app)

  index: (req, res, obj, detail=false) ->
    params = {}
    client = controllerBase.getClient req, obj, true
    client['roles'].all params, (err, data) ->
      if err
        logger.error "Failed to get role list"
        res.send err, obj._ERROR_400
      else
        res.send(data)

module.exports = RoleController
