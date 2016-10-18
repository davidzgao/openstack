# Copyright (c) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

utils = require('../utils/utils').utils
openclient = require 'openclient'

_DEFAULT_OPS =
  service: 'compute'
  profile: 'servers'
  alias: undefined

###*
 # Base controller which is used to handle http request.
 # By default, handle post/update/get/delete method.
###
class ControllerBase
  # http error with 400.
  _ERROR_400: 400

  constructor: (options=_DEFAULT_OPS) ->
    @profile = options.profile
    @service = options.service
    @alias = options.alias || options.profile
    @baseUrl = options.baseUrl
    @client = undefined
    @adder = options.adder || ""

  ###*
   # Routes config.
   # list/get/update/del/create Routes
   # are available.
   #
   # @param: {object} express application object.
   #
  ###
  config: (app) ->
    obj = @
    index = @index
    show = @show
    update = @update
    del = @del
    create = @create
    @debug = 'production' != app.get('env')
    profile = "/#{@profile}"
    if @adder
      profile = "/#{@adder}/#{@profile}"
    app.get "#{profile}", (req, res) ->
      if not ControllerBase.checkToken req, res
        return
      index req, res, obj
    app.get "#{profile}/detail", (req, res) ->
      if not ControllerBase.checkToken req, res
        return
      index req, res, obj, detail=true
    app.get "#{profile}/:id", (req, res) ->
      if not ControllerBase.checkToken req, res
        return
      show req, res, obj
    app.put "#{profile}/:id", (req, res) ->
      if not ControllerBase.checkToken req, res
        return
      update req, res, obj
    app.post "#{profile}", (req, res) ->
      if not ControllerBase.checkToken req, res
        return
      create req, res, obj
    app.del "#{profile}/:id", (req, res) ->
      if not ControllerBase.checkToken req, res
        return
      del req, res, obj
    return

  @checkToken: (req, res) ->
    if !req.session || !req.session.token
      res.send {'auth_error': 'auth error'}, 401
      return false
    return true

  @getBaseUrl: (req, obj, admin) ->
    regions = req.session.regions
    obj.baseUrl = utils.getURLByRegions regions, obj.service, admin
    return obj.baseUrl

  @getClient: (req, obj, admin=false) ->
    if obj.getBaseUrl
      baseUrl = obj.getBaseUrl req, obj, admin
    else
      baseUrl = ControllerBase.getBaseUrl req, obj, admin
    version = global.cloudAPIs.version[obj.service]
    service = openclient.getAPI "openstack", obj.service, version
    obj.client = new service(
      url: baseUrl
      scoped_token: req.session.token
      tenant: req.session.tenant.id
      debug: obj.debug
    )
    obj.client

  index: (req, res, obj, detail=false) ->
    params = {query: {}}
    # set params for query.
    for query of req.query
      # skip _, _cache query.
      if query == '_' or query == '_cache'
        continue
      params.query[query] = req.query[query]
    if detail
      params["detail"] = detail
    client = ControllerBase.getClient req, obj
    client[obj.alias].all params, (err, data) ->
      if err
        logger.error "Failed to get #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        res.send data
    return

  show: (req, res, obj) ->
    id = req.params.id
    params =
      id: id
      query: {}
    for query of req.query
      # skip _, _cache query.
      if query == '_' or query == '_cache'
        continue
      params.query[query] = req.query[query]
    client = ControllerBase.getClient req, obj
    client[obj.alias].get params, (err, data) ->
      if err
        logger.error "Failed to get #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        res.send data
    return

  create: (req, res, obj) ->
    params =
      data: req.body
    client = ControllerBase.getClient req, obj
    client[obj.alias].create params, (err, data)->
      if err
        logger.error "Failed to create #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        res.send data
    return

  update: (req, res, obj) ->
    params =
      data: req.body
      id: req.params.id
    client = ControllerBase.getClient req, obj
    client[obj.alias].update params, (err, data) ->
      if err
        logger.error "Failed to update #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        res.send(data)
    return

  del: (req, res, obj) ->
    params =
      id: req.params.id
    client = ControllerBase.getClient req, obj
    client[obj.alias].del params, (err, data) ->
      if err
        logger.error "Failed to delete #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        res.send data
    return

exports.ControllerBase = ControllerBase
