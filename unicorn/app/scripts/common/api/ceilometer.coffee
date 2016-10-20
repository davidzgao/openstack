'use strict'

$unicorn.listWorkflowLog = ($http, $window, $q, query, callback) ->
  serverURL = $window.$UNICORN.settings.serverURL
  alarm_logs = $http.get("#{serverURL}/workflow_events", {
    params: query
  }).success (logs) ->
      userList = []
      for log in logs.list
        log.traits = $unicorn.message._parseTrait log
        if log.event_type == 'workflow.completed'
          log.state = 'completed'
        if log.event_type == 'workflow.rejected'
          log.state = 'rejected'
        if log.event_type == 'workflow.canceled'
          log.state = 'canceled'
        if log.event_type == 'workflow.outdated'
          log.state = 'outdated'
        if log.user_id and log.user_id not in userList
          userList.push log.user_id

      $http.get("#{serverURL}/users/query", {
        params:
          ids: JSON.stringify userList
          fields: '["name"]'
      }).success (users) ->
        for log in logs.list
          log.user_name = if users[log.user_id] then users[log.user_id].name else _('None')
        callback logs.list, logs.total

$unicorn.readWorkflowLog = ($http, $window, eventId, callback) ->
  serverURL = $window.$UNICORN.settings.serverURL
  logParam = "#{serverURL}/workflow_events/#{eventId}"
  $http.put logParam, {data: ''}
    .success (data, status, headers) ->
      callback()
    .error (data, status, headers) ->
      toastr.error _("Failed to update workflow logs!")


$unicorn.getProjectList = ($http, $window, $q, callback) ->
  serverURL = $window.$UNICORN.settings.serverURL
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
