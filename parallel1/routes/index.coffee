'use strict'

openclient = require 'openclient'
utils = require('../utils/utils').utils
organize_catalog = require('./keystone/login').organize_catalog

exports.index = (req, res) ->
  res.sendFile('index.html')

exports.endpoints = (req, res) ->
  currentRegion = req.session.current_region
  if req.session.regions
    for region in req.session.regions
      if region.name == currentRegion
        res.send region.endpoints
        break

exports.auth = (req, res) ->
  if req.query.dash == "admin"
    if req.session.adminBack
      back = req.session.adminBack
      req.session.token = back.token
      req.session.tenant = back.tenant
      req.session.serviceCatalog = back.serviceCatalog
      organize_catalog(req.session, req.session.serviceCatalog)
      messageAuth = "#{back.token.id}H#{back.tenant.id}"
      req.session.save()
  if req.session.token
    expiredAt = Date.parse req.session.token.expires
    currentTime = new Date().getTime()
    if expiredAt > currentTime
      # Get services list
      if req.query.getService
        services = []
        regions = req.session.regions
        if regions
            for region in regions
              if region.active
                for service in region.endpoints
                  services.push service.type
        else
          for service in req.session.serviceCatalog
            services.push service.type
        res.send services
      else
        messageAuth = "#{req.session.token.id}"
        messageAuth += "H#{req.session.tenant.id}"
        userData =
          auth: messageAuth
          user: req.session.user
          project: req.session.tenant
        if req.query.unicorn
          userData.projects = req.session.projects
        res.send userData
    else
      req.session.destroy()
      res.send {"error": "need login"}, 401
  else
    req.session.destroy()
    res.send {"error": "need login"}, 401


exports.service = (req, res) ->
  services = []
  if not req.session.serviceCatalog
    res.send("No service available.", 404)
    return

  for service in req.session.serviceCatalog
    endpoint = service.endpoints[0]
    url = endpoint.publicURL
    item =
      name: service.name
      type: service.type
      host: url
      region: endpoint.region
    services.push item
  res.send(services)


exports.userProjects = (req, res) ->
  projects = []
  if not req.session.token
    res.send("User was unauthorized.", 401)
    return
  else
    expiredAt = Date.parse req.session.token.expires
    currentTime = new Date().getTime()
    if expiredAt < currentTime
      res.send({"error": "need login"}, 401)
      return

  if not req.session.projects
    res.send("No projects available.", 404)
    return

  for project in req.session.projects
    if not project.enabled
      continue
    item =
      name: project.name
      id: project.id
    projects.push item
  res.send(projects)


exports.switchProject = (req, res) ->
  projectId = req.params['project_id']
  session = req.session
  keystone = openclient.getAPI(
    "openstack", "identity",
    cloudAPIs.version.identity)
  if not session.adminBack
    tenant = session.tenant
    token = session.token
    catalog = session.serviceCatalog
    baseUrl = utils.getURLByCatalog catalog, 'identity', true
    keystoneClient = new keystone(
      url: baseUrl
      scoped_token: token
      tenant: tenant.id
      debug: true
    )
    keystoneClient.authenticate
      token: session.token.id
      project_id: projectId
      success: (token)->
        req.session.token = token.scoped_token
        req.session.tenant = token.tenant
        req.session.serviceCatalog = token.service_catalog
        organize_catalog(req.session, req.session.serviceCatalog)
        req.session.save()
        auth = "#{req.session.token.id}H#{req.session.tenant.id}"
        res.send {
          auth: auth
          user: req.session.user
          project: req.session.tenant}
      error: (err) ->
        res.send "authenticat error: #{err}", 500
    return
  tenant = session.adminBack.tenant
  token = session.adminBack.token
  catalog = session.adminBack.serviceCatalog
  baseUrl = utils.getURLByCatalog catalog, 'identity', true
  keystoneClient = new keystone(
    url: baseUrl
    scoped_token: token
    tenant: tenant.id
    debug: true
  )
  # Add `Member` role to current user for this project
  # and then get token for this project.
  if not session.roles
    res.send "can not get roles", 500
  keystoneClient.user_roles.create
    project: projectId
    user: session.user.id
    role: session.roles[global.memberRole]
    success: ->
      keystoneClient.authenticate
        token: session.token.id
        project_id: projectId
        success: (token) ->
          if not req.session.adminBack
            req.session.adminBack =
              token: req.session.token
              tenant: req.session.tenant
              serviceCatalog: req.session.serviceCatalog
              regions: req.session.regions
          req.session.token = token.scoped_token
          req.session.tenant = token.tenant
          req.session.serviceCatalog = token.service_catalog
          organize_catalog(req.session, req.session.serviceCatalog)
          req.session.save()
          res.send {
            auth: req.session.token.id
            user: req.session.user
            project: req.session.tenant}
        error: (err) ->
          res.send "authenticat error: #{err}", 500
    error: (err) ->
      # If add `Member` role confilct,
      # authenticate directly.
      if err.status == 409
        keystoneClient.authenticate
          token: session.token.id
          project_id: projectId
          success: (token)->
            if not req.session.adminBack
              req.session.adminBack =
                token: req.session.token
                tenant: req.session.tenant
                serviceCatalog: req.session.serviceCatalog
                regions: req.session.regions
            req.session.token = token.scoped_token
            req.session.tenant = token.tenant
            req.session.serviceCatalog = token.service_catalog
            organize_catalog(req.session, req.session.serviceCatalog)
            req.session.save()
            auth = "#{req.session.token.id}H#{req.session.tenant.id}"
            res.send {
              auth: auth
              user: req.session.user
              project: req.session.tenant}
          error: (err) ->
            res.send "authenticat error: #{err}", 500
      else
        res.send "authenticat error: #{err}", 500
