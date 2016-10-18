'use strict'

$cross.deleteAlarmRule = ($http, $window, ruleId, callback) ->
  if !ruleId
    return
  serverURL = $window.$CROSS.settings.serverURL
  ruleParam = "#{serverURL}/alarm_rule/#{ruleId}"
  $http.delete ruleParam
    .success (data, status, headers) ->
      callback status
    .error (data, status, headers) ->
      callback status

$cross.listAlarmRule = ($http, $window, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  rulesParam = "#{serverURL}/alarm_rule"
  $http.get rulesParam
    .success (data, status, headers) ->
      callback data
    .error (data, status, headers) ->
      toastr.error _("Failed to list alarm rules!")

$cross.getAlarmRule = ($http, $window, ruleId, callback) ->
  if !ruleId
    return
  serverURL = $window.$CROSS.settings.serverURL
  ruleParam = "#{serverURL}/alarm_rule/#{ruleId}"
  $http.get ruleParam
    .success (data, status, headers) ->
      callback data
    .error (data, status, headers) ->
      toastr.error _("Failed to get alarm rule!")

$cross.getProjectList = ($http, $window, $q, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  projectParam = "#{serverURL}/projectsV3"

  projectList = $http.get projectParam
    .then (response) ->
      return response.data

  $q.all ([projectList])
    .then (values) ->
      if values
        projectList = []
        for item in values[0].data
          project = {}
          project['project_name'] = item['name']
          project['tenant_id'] = item['id']
          projectList.push project
        callback projectList
      else
        toastr.error _("Failed to get List!")

$cross.listAlarmLog = ($http, $window, $q, query, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  alarm_logs = $http.get("#{serverURL}/resource_alarm_history", {
    params: query
  }).success (alarm_logs) ->
      resourceMap = {
        'instance': _('Instance')
        'hardware': _('Host')
      }
      logTypeMap = {
        'alarm': _("Alarm Occur")
        'ok': _("Alarm Clear")
      }

      logList = []
      instanceList = []
      for log in alarm_logs.list
        log.resource_type = resourceMap[log.reason_data.resource_type or 'instance']
        if log.reason_data.resource_type == 'instance'
          instanceList.push log.resource_id
        log.resource_id = log.resource_id
        log.type = logTypeMap[log.state or 'alarm']
        msg = "Alarm is %(state)s as %(statistic)s of " +\
              "%(meter)s is %(comparison)s than %(compare)s in %(interval)s seconds."
        log.alarm_meta = _([msg, log.alarm_meta])
        logList.push log

      instanceURL = "#{serverURL}/servers/query"
      $http.get(instanceURL, {
        params:
          ids: JSON.stringify instanceList
          fields: '["name"]'
      }).success (data, status, headers) ->
          for log in alarm_logs.list
            if log.reason_data.resource_type == 'instance'
              log.resource_name = \
              data[log.resource_id] or null
              if log.resource_name
                log.resource_name = \
                  log.resource_name.name
            else
              log.resource_name = log.resource_id
          callback logList, alarm_logs.total, alarm_logs.localeTime
        .error (data, status, headers) ->
          callback logList, alarm_logs.total, alarm_logs.localeTime

$cross.readAlarmLog = ($http, $window, historyId, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  logParam = "#{serverURL}/resource_alarm_history/#{historyId}"
  $http.put logParam, {data: ''}
    .success (data, status, headers) ->
      callback()
    .error (data, status, headers) ->
      toastr.error _("Failed to update alarm logs!")

$cross.listWorkflowLog = ($http, $window, $q, query, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  alarm_logs = $http.get("#{serverURL}/workflow_events", {
    params: query
  }).success (logs) ->
      userList = []
      projectList = []
      for log in logs.list
        log.traits = $cross.message._parseTrait log
        if log.user_id and log.user_id not in userList
          userList.push log.user_id
        if log.project_id and log.project_id not in projectList
          projectList.push log.project_id

      userHttp = $http.get "#{serverURL}/users/query", {
        params:
          ids: JSON.stringify userList
          fields: '["name"]'
      }
      projectHttp = $http.get "#{serverURL}/projects/query", {
        params:
          ids: JSON.stringify projectList
          fields: '["name"]'
      }
      $q.all([userHttp, projectHttp])
        .then (res) ->
          users = res[0].data
          projects = res[1].data
          for log in logs.list
            log.user_name = if users[log.user_id] then users[log.user_id].name else _('None')
            log.project_name = if projects[log.project_id] then projects[log.project_id].name else _('None')
          callback logs.list, logs.total, logs.localeTime

$cross.readWorkflowLog = ($http, $window, eventId, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  logParam = "#{serverURL}/workflow_events/#{eventId}"
  $http.put logParam, {data: ''}
    .success (data, status, headers) ->
      callback()
    .error (data, status, headers) ->
      toastr.error _("Failed to update workflow logs!")
