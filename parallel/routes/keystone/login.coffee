"use strict"

openclient = require("openclient")
utils = require('../../utils/utils').utils
crypto = require('crypto')
storage = require('ecutils').storage
redis = require('ecutils').redis
register = require('../../node_modules/openclient/workflow/versions')
http = require('http')

_organize_catalog = (session, serviceCatalog) ->
  ###
  #  Save organized endpoints into req.session
  #  req.session.regions:
  #    type: list
  #    example:
  #      [{
  #        name: 'region1'
  #        endpoints: []
  #      }]
  #
  #  Set the frist to active
  ###
  preRegionName = null
  if session.regions
    for region in session.regions
      if region.active
        preRegionName = region.name
        break

  regionsMap = {}
  if serviceCatalog
    for service in serviceCatalog
      for endpoint in service.endpoints
        endpoint.service_name = service.name
        endpoint.type = service.type
        if regionsMap[endpoint.region]
          regionsMap[endpoint.region].push endpoint
        else
          regionsMap[endpoint.region] = [endpoint]
  regions = []
  for key, value of regionsMap
    regionObj = {
      name: key
      endpoints: value
    }
    if preRegionName
      if key == preRegionName
        regionObj.active = true
        session.current_region = regionObj.name
    regions.push regionObj

  if regions.length > 0 and not preRegionName
    regions[0].active = true
    session.current_region = regions[0].name
  session.regions = regions

###
Get user scoped token via keystone API.

NOTE(zhengyue): The project used is the first at project
                list from API call.

Example:
    POST /login

Body:
   {username: 'Bob', password: 'Bob-secret'}

@param require the staandard http request
@param response the standard http response
###
exports.login = (req, res) ->
  # TODO: zhengyue Use logger
  keystone = openclient.getAPI(
    "openstack", "identity",
    cloudAPIs.version.identity)
  # TODO: zhengyue Config debug
  keystoneClient = new keystone(
    url: cloudAPIs.keystone.authUrl
    debug: true
  )

  assgineMemberRole = (token) ->
    catalog = token.service_catalog
    baseUrl = utils.getURLByCatalog catalog, 'identity', true
    client = new keystone(
      url: baseUrl
      scoped_token: token.scoped_token
      tenant: token.tenant.id
      debug: true
    )
    client.roles.all
      success: (roles) ->
        memberRoleId = null
        defaultMemberRoleName = "Member"
        if cloudAPIs.member_role
          defaultMemberRoleName = cloudAPIs.member_role
        for role in roles
          if role.name == defaultMemberRoleName
            memberRoleId = role.id
            break
        if memberRoleId
          params =
            headers:
              "Content-length": 0
            endpoint_type: 'identity'
            project: token.tenant.id
            user: token.user.id
            role: memberRoleId
            data: {}
          client.user_roles.create params, (err, data) ->
            if err
              logger.error "Failed to assgine member role"

  requireNormal = req.body.normal
  # TODO: zhengyue shorten the function
  keystoneClient.authenticate
    username: req.body.username
    password: req.body.password
  , (err, unscopedToken) ->
    if err
      if err.status == 401
        baseUrl = global.cloudAPIs.register.baseUrl
        query = { name: req.body.username}
        registerValidate = register[register.current]
        registerClient = new registerValidate(
          url: baseUrl
          debug: true
        )
        registerClient['register'].validate query, (err, data) ->
          if err
            res.send err, err.status || 500
          else
            if data.has == 1
              redisClient = redis.connect({'redis_host': redisConf.host})
              debugInfo = true
              storageClient = new storage.Storage({
                redis_client: redisClient
                debug: debugInfo
              })
              openstackServices = [
                'nova'
                'heat'
                'gossip'
                'cinder'
                'neutron'
                'econe'
                'glance'
                'highland'
                'ceilometer'
              ]
              storageClient.getObjects
                resource_type: 'users'
                debug: debugInfo
              , (err, users) ->
                if users
                  for user in users.data
                    if user in openstackServices
                      continue
                    else
                      if user.username == req.body.username
                        if user.enabled == 'false'
                          res.send "User has been disabled.", 401
                          return
                        else
                          res.send "Username and password are not match!", 401
                          return
                        break
                else
                  res.send err, err.status || 500
            else if data.has == 0
              res.send "User is not exist.", 401
              return
            else
              res.send "User in the workflow.", 401
              return
      else
        res.send err, err.status || 500
        return
    if unscopedToken
      keystoneClient.projects.all
        username: req.body.username
        password: req.body.password
        token: unscopedToken.token.id
        success: (projects) ->
          project = undefined
          if requireNormal
            permiPros = []
            projectEnabled = undefined
            for pro in projects
              if pro.name == global.adminProject or pro.enabled == false
                continue
              permiPros.push pro
            if not permiPros.length
              res.send "No available projects.", 402
              return
            project = permiPros[0]
          else
            isAdmin = false
            for pro in projects
              if pro.name == global.adminProject
                project = pro
                isAdmin = true
                break
            if not isAdmin
              res.send "Not admin user", 402
              return
          keystoneClient.authenticate
            username: req.body.username
            password: req.body.password
            project: project.name
            success: (token) ->
              roles = token.user.roles
              if not roles or not roles.length
                res.send "No available roles", 402
                return
              noMemberRole = true
              defaultMemberRoleName = "Member"
              if cloudAPIs.member_role
                defaultMemberRoleName = cloudAPIs.member_role
              for role in roles
                if role.name == defaultMemberRoleName
                  noMemberRole = false
              if noMemberRole
                # Assgine Member role for this user
                assgineMemberRole(token)
              if requireNormal
                req.session.projects = permiPros
                req.session.token = token.scoped_token
                req.session.serviceCatalog = token.service_catalog
                _organize_catalog(req.session, req.session.serviceCatalog)
                req.session.user = token.user
                req.session.tenant = token.tenant
                # NOTE(ZhengYue): Save the crycted password for compair
                password = req.body.password
                sha1Hash = crypto.createHash('sha1')
                encryptedPassword = sha1Hash.update(password).digest('hex')
                req.session.password = encryptedPassword
                # TODO: zhengyue Unify response
                res.send {success: 'success'}
                return

              # Store roles for admin user login.
              catalog = token.service_catalog
              baseUrl = utils.getURLByCatalog catalog, 'identity', true
              client = new keystone(
                url: baseUrl
                scoped_token: token.scoped_token
                tenant: token.tenant.id
                debug: true
              )
              client.roles.all
                success: (roles) ->
                  roleDict = {}
                  for role in roles
                    roleDict[role.name] = role.id
                  req.session.roles = roleDict
                  req.session.token = token.scoped_token
                  req.session.serviceCatalog = token.service_catalog
                  _organize_catalog(req.session, req.session.serviceCatalog)
                  req.session.user = token.user
                  req.session.tenant = token.tenant
                  req.session.adminBack =
                    token: token.scoped_token
                    tenant: token.tenant
                    serviceCatalog: token.service_catalog
                    regions: req.session.regions
                  # NOTE(ZhengYue): Save the crycted password for compair
                  password = req.body.password
                  sha1Hash = crypto.createHash('sha1')
                  encryptedPassword = sha1Hash.update(password).digest('hex')
                  req.session.password = encryptedPassword
                  req.session.save()
                  # TODO: zhengyue Unify response
                  res.send {success: 'success'}
                error: (err) ->
                  res.send "can not get roles: #{err}", 500
            error: (err) ->
              res.send err, err.status || 500
        error: (err) ->
          res.send err, err.status || 500
    return

  return

###
Check user is login or not.

@param require the staandard http request
@param response the standard http response
###
exports.isLogin = (req, res, next) ->
  if req.session.token
    expiredAt = Date.parse req.session.token.expires
    currentTime = new Date().getTime()
    if (expiredAt - currentTime) > 0
      next()
    else
      # TODO: zhengyue Unify response
      res.send {"error": "need login"}, 401
  else
    # TODO: zhengyue Unify response
    res.send {"error": "need login"}, 401

  return

###
User logout.

@param require the staandard http request
@param response the standard http response
###
exports.logout = (req, res) ->
  req.session.destroy()
  # TODO: zhengyue Unify response
  res.send {'logout': 'success'}, 200

  return

module.exports.organize_catalog = _organize_catalog
