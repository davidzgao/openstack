# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

controllerBase = require('../controller').ControllerBase

###*
 # server controller.
###
class RoleController extends controllerBase

  constructor: () ->
    options =
      service: 'deployment'
      profile: 'deploy/role'
      alias: 'deployRoles'
    super(options)

  index: (req, res, obj, detail=false) ->
    params = {query: {}}
    params.project = req.session.tenant.id
    # set params for query.
    for query of req.query
      # skip _, _cache query.
      if query == '_' or query == '_cache'
        continue
      params.query[query] = req.query[query]
    if detail
      params["detail"] = detail
    client = controllerBase.getClient req, obj
    client[obj.alias].all params, (err, data) ->
      if err
        logger.error "Failed to get #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        res.send data
    return


module.exports = RoleController
