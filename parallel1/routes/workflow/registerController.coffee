# Copyright (Gc) 2014. This file is confidential and proprietary.
# All Rights Reserved, Microchild Technologies (http://www.microchild.com)

'use strict'

openclient = require("openclient")
controllerBase = require('../controller').ControllerBase
emailSender = require('../../utils/email').EmailSender
userController = require('../keystone/usersController')
redis = require('ecutils').redis
storage = require('ecutils').storage
crypto = require('crypto')
util = require('../../utils/utils').utils

###*
 # Register controller.
###

class RegisterController extends controllerBase

  debug: true
  constructor: () ->
    options =
      service: 'workflow'
      profile: 'register'
    super(options)
    @redisClient = redis.connect({'redis_host': redisConf.host})

  getClient: (req, obj) ->
    baseUrl = global.cloudAPIs.register.baseUrl
    obj.baseUrl = baseUrl
    version = global.cloudAPIs.version[obj.service]
    workflow = openclient.getAPI "openstack", obj.service, version
    obj.client = new workflow(
      url: baseUrl
      debug: obj.debug
    )
    return obj.client

  config: (app) ->
    obj = @
    register = @register
    validate = @validate
    checkExpire = @checkExpire
    passwordRetrieve = @retrieve
    passwordReset = @passwordReset

    app.get "/#{@profile}", (req, res) ->
      validate req, res, obj
    app.post "/#{@profile}", (req, res) ->
      register req, res, obj

    app.post "/password/reset", (req, res) ->
      passwordReset req, res, obj
    app.post "/password/reset/check", (req, res) ->
      checkExpire req, res, obj
    app.post "/password/retrieve", (req, res) ->
      passwordRetrieve req, res, obj

    @debug = 'production' != app.get('env')
    @storage = new storage.Storage({
      redis_client: @redisClient
      debug: @debug
    })

    return

  validate: (req, res, obj) ->
    client = obj.getClient(req, obj)
    client['register'].validate req.query, (err, data) ->
      if err
        res.send err, err.status
      else
        res.send data

  register: (req, res, obj) ->
    params =
      data: req.body
    client = obj.getClient(req, obj)
    client['register'].register params, (err, data) ->
      if err
        res.send err, err.status
      else
        res.send data

  @checkEmail: (userList, email) ->
    has = false
    matchedUser = undefined
    adminUser = global.adminUserConf.name
    isAdmin = false
    for user in userList
      if user.name == adminUser
        isAdmin = true
        break
      if email == user.email
        has = true
        matchedUser = user
        break
    return {has: has, matchedUser: matchedUser, isAdmin: isAdmin}

  @createURLHash: (userId, expireAt) ->
    Date.prototype.addHours = (hours) ->
      this.setHours(this.getHours() + hours)
      return this

    md5Encoder = crypto.createHash("md5")
    currentDate = new Date()
    urlExpireHours = global.passwordResetConf["URLExpireHours"]
    urlSecureKey = global.passwordResetConf["URLSecureKey"]
    if !expireAt
      expireAt = currentDate.addHours(urlExpireHours).getTime()
    combinationStr = userId + expireAt + urlSecureKey
    combinationHash = util.urlHashEncode md5Encoder, combinationStr
    # NOTE (ZhengYue): Replace the '/' in hash, because the '/' will
    # cause confusion in URL.
    # Encode the url to avoid the specific symbol
    combinationHash = encodeURI(combinationHash)
    combinationHash = combinationHash.replace(/[\/]/g, "a")
    combinationHash = combinationHash.replace(/[\+]/g, "a")
    urlParams = {
      hash: combinationHash
      expireAt: expireAt
    }
    return urlParams

  retrieve: (req, res, obj) ->
    # Function for receive the email for password retrieve
    client = obj.getClient(req, obj)
    # Get all user, and check email which received is in the user list
    obj.storage.getObjects
      resource_type: 'users'
      query: {}
      debug: obj.debug
    , (err, users) ->
      judge = RegisterController.checkEmail(users.data, req.body.email)
      if judge.has == false
        if judge.isAdmin
          res.send {error: 'The password of admin could not to reset!'}, 400
        res.send {error: 'email not exist'}, 400
      else
        # Construct the URL for reset password and send email.
        matchedUser = judge.matchedUser
        userId = matchedUser.id

        urlParams = RegisterController.createURLHash(userId)
        hash = urlParams.hash
        expireAt = urlParams.expireAt
        hostURL = req.headers.referer + "#/reset/"
        markUpURL = "#{hostURL}#{userId}/#{expireAt}/#{hash}"

        mailSubject = i18n.__("Reset password")
        mailContent = i18n.__("Please click link to reset password: ")
        mailTips = i18n.__("This is a auto-send mail, please don't reply.")
        link = i18n.__("Reset password")
        emailOptions = {
          to: matchedUser.email
          subject: mailSubject
          text: ''
          html: "<p>#{mailContent}<a href='#{markUpURL}'>#{link}</a></p><p>#{mailTips}</p>"
        }
        (new emailSender(emailOptions)).sendMail((err, response) ->
          res.send {}, 202
        )

  passwordReset: (req, res, obj) ->
    # Check the url params is correct
    timeExpired = true
    hashFailed = true
    currentDate = (new Date()).getTime()
    expirAt = req.body.params.expirAt
    if currentDate < expirAt
      timeExpired = false
    userId = req.body.params.userId
    urlParams = RegisterController.createURLHash(userId, expirAt)
    hashFromURL = req.body.params.hash
    if urlParams.hash == hashFromURL
      hashFailed = false
    else
      hashFailed = true

    if timeExpired or hashFailed
      res.send {error: "Url check failed!"}, 401
      return
    # Request the token via admin's username, password and tenant_name
    adminUser = global.adminUserConf
    username = adminUser.username
    password = adminUser.password
    tenant_name = adminUser.tenant
    keystone = openclient.getAPI(
      "openstack", "identity", cloudAPIs.version.identity)
    keystoneClient = new keystone(
      url: cloudAPIs.keystone.authUrl
      debug: obj.debug
    )
    keystoneClient.authenticate
      username: username
      password: password
      project: tenant_name
    , (err, scopedToken) ->
      userCtrl = new userController()
      callback = (res, err, data) ->
        if err
          logger.error "Failed to reset password!"
          res.send err, 400
        else
          res.send {}, 202
        return

      options = {
        req: req
        obj: userCtrl
        token: scopedToken.token
        tenant_id: scopedToken.token.tenant.id
        callback: callback
        res: res
      }
      userCtrl.update_password options

  checkExpire: (req, res, obj) ->
    # Check the hash and expir time
    timeExpired = true
    hashFailed = true
    currentDate = (new Date()).getTime()
    expirAt = req.body.expirAt
    if currentDate < expirAt
      timeExpired = false
    userId = req.body.userId
    urlParams = RegisterController.createURLHash(userId, expirAt)
    hashFromURL = req.body.hash
    if urlParams.hash == hashFromURL
      hashFailed = false
    else
      hashFailed = true
    if timeExpired == false and hashFailed == false
      res.send {success: 'ok'}, 200
    else if timeExpired == true
      res.send {error: 'time expired'}, 400
    else if hashFailed == true
      res.send {error: 'URL error'}, 401

module.exports = RegisterController
