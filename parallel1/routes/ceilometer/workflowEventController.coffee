'use strict'

controllerBase = require("../controller").ControllerBase

class WorkflowEventController extends controllerBase
  constructor: () ->
    options =
      service: 'metering'
      profile: 'workflow_events'
      alias: 'workflow_event'
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
        # localueTime is used to caculation how long did
        # workflow event took ago
        data.localeTime = (new Date()).getTime()
        res.send data
    return

module.exports = WorkflowEventController
