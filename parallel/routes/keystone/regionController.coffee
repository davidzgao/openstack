'use strict'

controllerBase = require('../controller').ControllerBase
redis = require('ecutils').redis
storage = require('ecutils').storage
openclient = require 'openclient'


class RegionController extends controllerBase

  constructor: () ->
    options =
      service: 'identity'
      profile: 'regions'
      baseUrl: global.cloudAPIs.keystone.v3
    super(options)

  config: (app) ->
    obj = this
    index = @index
    switchRegion = @switchRegion
    app.get "/regions", (req, res) ->
      index req, res, obj

    app.post "/regions/switch", (req, res) ->
      switchRegion req, res, obj

    super(app)

  getClient: (req, obj) ->
    baseUrl = obj.baseUrl
    version = global.cloudAPIs.version['project']
    service = openclient.getAPI "openstack", obj.service, version
    obj.client = new service(
      url: baseUrl
      scoped_token: req.session.token
      tenant: req.session.tenant.id
      debug: obj.debug
    )
    obj.client

  index: (req, res, obj) ->
    if not controllerBase.checkToken req, res
      return

    client = obj.getClient req, obj
    client['regions'].all {}, (err, data, status) ->
      if not req.session.regions
        res.send []
        return
      for service in req.session.regions
        if not data
          return
        for region in data
          if region.id == service.name
            service.extra = region.extra
      res.send req.session.regions
    return

  switchRegion: (req, res, obj) ->
    if not controllerBase.checkToken req, res
      return
    if not req.body.region
      return

    for region in req.session.regions
      if region.name == req.body.region
        region.active = true
        req.session.current_region = region.name
      else
        region.active = false
    res.send req.session.regions
    return

module.exports = RegionController
