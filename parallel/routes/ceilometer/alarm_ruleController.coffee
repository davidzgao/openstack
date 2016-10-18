'use strict'

controllerBase = require('../controller').ControllerBase
redis = require('ecutils').redis
storage = require('ecutils').storage
async = require('async')

class AlarmRuleController extends controllerBase

    constructor: () ->
      options =
        service: 'metering'
        profile: 'alarm_rule'
        alias: 'alarm'
      super(options)

    config: (app) ->
      obj = @
      @debug = 'production' != app.get('env')
      super(app)

    @queryRelative: (options, callback) ->
      redisClient = redis.connect(
        'redis_host': redisConf.host
        'redis_password': redisConf.pass
        'redis_port': redisConf.port
      )
      storage = require('ecutils').storage
      storageObj = new storage.Storage({
        redis_client: redisClient
        debug: true
      })
      storageObj.getObjectsByIds options.params, (err, data) ->
        if err
          resource_type = options.params.resource_type
          logger.error "Failed to get #{resource_type} as: ", err
          callback err, []
        else
          callback null, data

    @assembleQuery: (rule) ->
      userIds = [rule.user_id]
      userOptions =
        params:
          ids: userIds
          fields: ['name']
          resource_type: 'users'
      return [userOptions]

    index: (req, res, obj) ->
      params = {query: {}}
      # set params for query.
      for query of req.query
        # skip _, _cache query.
        if query == '_' or query == '_cache'
          continue
        params.query[query] = req.query[query]
      client = controllerBase.getClient req, obj
      client[obj.alias].all params, (err, rules) ->
        if err
          logger.error "Failed to get #{obj.alias} as: ", err
          res.send err, obj._ERROR_400
        else
          res.send rules

    show: (req, res, obj) ->
      # set params for query.
      params =
        id: req.params.id
        query: {}
      for query of req.query
        # skip _, _cache query.
        if query == '_' or query == '_cache'
          continue
        params.query[query] = req.query[query]
      client = controllerBase.getClient req, obj
      client[obj.alias].get params, (err, rule) ->
        if err
          logger.error "Failed to get #{obj.alias} as: ", err
          res.send err, obj._ERROR_400
        else
          options = AlarmRuleController.assembleQuery(rule)
          async.map(options, AlarmRuleController.queryRelative,
          (err, results) ->
            if err
              res.send rule
            else
              userMap = results[0]
              if userMap[rule.user_id]
                rule.user_name = userMap[rule.user_id].name
              res.send rule
          )
    del: (req, res, obj) ->
      params =
        id: req.params.id
      params.headers = {
        'Content-Length': 0
      }
      client = controllerBase.getClient req, obj
      client[obj.alias].del params, (err, data) ->
        if err
          logger.error "Failed to delete #{obj.alias} as: ", err
          res.send err, obj._ERROR_400
        else
          res.send data
      return


module.exports = AlarmRuleController
