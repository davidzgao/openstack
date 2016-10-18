'use strict'

controllerBase = require('../controller').ControllerBase

class ResourceAlarmHistoryController extends controllerBase

  constructor: () ->
    options =
      service: 'metering'
      profile: 'resource_alarm_history'
      alias: 'resource_alarm_history'
    super(options)

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
    client = controllerBase.getClient req, obj
    client[obj.alias].all params, (err, data) ->
      if err
        logger.error "Failed to get #{obj.alias} as: ", err
        res.send err, obj._ERROR_400
      else
        # localeTime is used to caculation how long did
        # alarm took ago
        data.localeTime = (new Date()).getTime()
        res.send data
    return

module.exports = ResourceAlarmHistoryController
