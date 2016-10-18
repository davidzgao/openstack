'use strict'

projectAttrs = ['id', 'name', 'description', 'enabled']

userAttrs = ['id', 'name', 'enabled', 'email', 'tenantId']

class $cross.Project extends $cross.APIResourceWrapper
  constructor: (project, attrs) ->
    super project, attrs

class $cross.User extends $cross.APIResourceWrapper
  constructor: (user, attrs) ->
    super user, attrs

$cross.listProjects = ($http, $window, $q, query, callback) ->
  serverURL = $window.$CROSS.settings.serverURL

  if query.dataFrom != undefined
    query.limit_from = query.dataFrom
    delete query.dataFrom
  if query.dataTo != undefined
    query.limit_to = query.dataTo
    delete query.dataTo
  if query.search == true
    projectsURL = "#{serverURL}/projectsV3/search"
  else
    projectsURL = "#{serverURL}/projectsV3"

  projects = $http.get(projectsURL, {
    params: query
  }).then(
    (response) ->
      return response.data
    (error) ->
      return {data: [], total: 0}
  )

  $q.all([projects])
    .then (values) ->
      projectList = []
      for project in values[0].data
        # NOTE(ZhengYue): Hidden the 'unnecessary' projects
        hiddenProjects = $window.$CROSS.settings.hiddenProjects
        if project.name in hiddenProjects
          continue
        project = new $cross.Project(project, projectAttrs)
        projectObj = project.getObject(project)
        projectList.push projectObj

      callback projectList, values[0].total

$cross.updateProject = ($http, $window, options, callback) ->
  if !options.projectId
    return
  serverUrl = $window.$CROSS.settings.serverURL
  projectParams = "projectsV3/#{options.projectId}"
  params = {
    description: options.description
    name: options.name
  }
  $http.put "#{serverUrl}/#{projectParams}", params
    .success (data, status, headers) ->
      callback data
    .error (data, status, headers) ->
      toastr.error data

$cross.projectTrigger = ($http, $window, options, callback) ->
  if !options.projectId
    return
  serverUrl = $window.$CROSS.settings.serverURL
  projectParams = "projectsV3/#{options.projectId}"
  if options.enabled == 'true'
    options.enabled = true
  else
    options.enabled = false
  params =
    enabled: options.enabled
  $http.put "#{serverUrl}/#{projectParams}", params
    .success (data, status, headers) ->
      callback status, data
    .error (data, status, headers) ->
      callback status, data

$cross.userTrigger = ($http, $window, options, callback) ->
  if !options.userId
    return
  serverUrl = $window.$CROSS.settings.serverURL
  userParam = "#{serverUrl}/users/#{options.userId}"
  if options.enabled == 'true'
    options.enabled = true
  else
    options.enabled = false
  params =
    enabled: options.enabled
  $http.put userParam, params
    .success (data, status, headers) ->
      callback status, data
    .error (data, status, headers) ->
      callback status, data

$cross.updateUser = ($http, $window, options, callback) ->
  if !options.userId
    return
  serverUrl = $window.$CROSS.settings.serverURL
  userParam = "#{serverUrl}/users/#{options.userId}"
  params = {
    name: options.name
    email: options.email
    tenantId: options.tenantId
    default_project_id: options.tenantId
  }
  if options.password
    params.password = options.password
  $http.put userParam, params
    .success (data, status, headers) ->
      callback data, status
    .error (data, status, headers) ->
      callback data, status

$cross.listProjectsOfUser = ($http, $window, userId, callback) ->
  if !userId
    return
  serverUrl = $window.$CROSS.settings.serverURL
  userParam = "#{serverUrl}/users/#{userId}/projects"
  $http.get userParam
    .success (data, status, headers) ->
      callback data
    .error (data, status, headers) ->
      callback data

$cross.listUsers = ($http, $window, $q, query, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  if query.dataFrom != undefined
    query.limit_from = query.dataFrom
    delete query.dataFrom
  if query.dataTo != undefined
    query.limit_to = query.dataTo
    delete query.dataTo
  if query.search == true
    usersURL = "#{serverURL}/users/search"
  else
    usersURL = "#{serverURL}/users"

  users = $http.get(usersURL, {
    params: query
  }).then(
    (response) ->
      return response.data
    (error) ->
      return {data: [], total: 0}
  )
  hiddenProjectNames = $window.$CROSS.settings.hiddenProjects
  hiddenProjects = []

  if hiddenProjectNames.length == 0
    $q.all([users])
      .then (values) ->
        callback values[0].data, values[0].total
    return

  memberships = $http.get("#{serverURL}/users/membership")

  # Filter the user in hidden projects, like 'service'
  allProjects = {}
  projectsParams = "projects"
  $http.get("#{serverURL}/#{projectsParams}")
    .then (response) ->
      for project in response.data.data
        if project.name in hiddenProjectNames
          hiddenProjects.push project.id
        allProjects[project.id] = project.name
      if hiddenProjects.length == 0
        return
      $q.all([users, memberships])
        .then (values) ->
          total = values[0].total
          membership = values[1].data
          belongs = {}
          for member in membership.data
            belongs[member.id] = member
          userList = []
          for user in values[0].data
            if user.tenantId in hiddenProjects
              continue
            else
              if belongs[user.id]
                member = belongs[user.id]
                if member.projects
                  belong = JSON.parse(member.projects)
                  user.projects = belong
              else
                if user.tenantId
                  user.projects = [{name: allProjects[user.tenantId]}]
                else if user.default_project_id
                  user.projects = [{
                    name:allProjects[user.default_project_id]
                  }]
              userList.push user
          callback userList, total

$cross.deleteUser = ($http, $window, userId, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  userParams = "#{serverURL}/users/#{userId}"
  $http.delete userParams
    .success (data, status, headers) ->
      callback data, status
    .error (data, status, headers) ->
      callback data, status

$cross.getUser = ($http, $window, userId, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  userParams = "#{serverURL}/users/#{userId}"
  $http.get userParams
    .success (data, status, headers) ->
      callback data, status
    .error (data, status, headers) ->
      callback data, status

$cross.listRoles = ($http, $window, $q, query, callback) ->
  serverUrl = $window.$CROSS.settings.serverURL
  roleParams = "roles"

  roles = $http.get("#{serverUrl}/#{roleParams}")
    .then (response) ->
      return response.data

  $q.all([roles])
    .then (values) ->
      callback values

$cross.listUserProjects = ($http, $window, $q, userId, callback) ->
  if !userId
    return
  serverUrl = $window.$CROSS.settings.serverURL
  projectsURL = "#{serverUrl}/users/#{userId}/projects"
  $http.get projectsURL
    .success (data, status, headers) ->
      callback data
    .error (data, status, headers) ->
      callback data

$cross.assginRole = ($http, $window, options, callback) ->
  if !options.projectId or !options.userId
    return
  serverUrl = $window.$CROSS.settings.serverURL
  roleParams = "membership/#{options.projectId}"
  body = {user: options.userId, role: options.roleId}
  roleURL = "#{serverUrl}/#{roleParams}"
  $http.post roleURL, body
    .success (data, status, headers) ->
      callback data, status
    .error (err, status, headers) ->
      callback err, status

$cross.removeRole = ($http, $window, options, callback) ->
  if !options.projectId or !options.userId
    return
  serverUrl = $window.$CROSS.settings.serverURL
  roleParams = "membership/#{options.projectId}/#{options.userId}"
  roleURL = "#{serverUrl}/#{roleParams}"
  $http.delete roleURL
    .success (data, status, headers) ->
      callback data, status
    .error (err, status, headers) ->
      callback err, status

$cross.listMembership = ($http, $window, $q, projectId, callback) ->
  if !projectId
    return
  serverUrl = $window.$CROSS.settings.serverURL

  membershipParams = "membership/#{projectId}"

  users = $http.get("#{serverUrl}/#{membershipParams}")
    .then (response) ->
      return response.data

  $q.all([users])
    .then (values) ->
      if values[0]
        callback values[0]

$cross.createProject = ($http, $window, options, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  projectsV3 = "#{serverURL}/projectsV3"
  $http.post projectsV3, options
    .success (data, status, headers) ->
      callback data, status
    .error (data, status, headers) ->
      callback data, status

$cross.deleteProject = ($http, $window, projectId, callback) ->
  if !projectId
    return
  serverURL = $window.$CROSS.settings.serverURL
  projectsV3 = "#{serverURL}/projectsV3/#{projectId}"
  $http.delete projectsV3
    .success (data, status, headers) ->
      callback data, status
    .error (data, status, headers) ->
      callback data, status

$cross.getProject = ($http, $window, projectId, callback) ->
  if !projectId
    return
  serverURL = $window.$CROSS.settings.serverURL
  projectsV3 = "#{serverURL}/projectsV3/#{projectId}"
  $http.get projectsV3
    .success (data, status, headers) ->
      callback data
    .error (data, status, headers) ->
      callback data

# Get project quota
# NOTE (ZhengYue): the quota API was belong to nova and cinder service
# But this mroe intimate with project.
$cross.getQuota = ($http, $window, $q, projectId, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  cinderQuotaParams = "#{serverURL}/cinder/os-quota-sets/#{projectId}/defaults"
  novaQuotaParams = "#{serverURL}/nova/os-quota-sets/#{projectId}/defaults"

  cinderQuota = $http.get cinderQuotaParams
    .then (response) ->
      return response.data
  novaQuota = $http.get novaQuotaParams
    .then (response) ->
      return response.data

  $q.all([cinderQuota, novaQuota])
    .then (values) ->
      if values
        callback values[0], values[1]
      else
        #TODO(ZhengYue): Tips for error
        console.log "Failed to get quota"

$cross.updateQuota = ($http, $window, $q, projectId, options, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  cinderQuotaParams = "#{serverURL}/cinder/os-quota-sets/#{projectId}/defaults"
  novaQuotaParams = "#{serverURL}/nova/os-quota-sets/#{projectId}/defaults"

  cinderQuota = $http.put cinderQuotaParams, options.cinderQuota
    .then (response) ->
      return response.data
  novaQuota = $http.put novaQuotaParams, options.novaQuota
    .then (response) ->
      return response.data

  $q.all([cinderQuota, novaQuota])
    .then (values) ->
      if values
        callback values
      else
        callback null

$cross.updateQuotaClass = ($http, $window, $q, projectId, options, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  delete options.cinderQuota.id
  delete options.novaQuota.id
  cinderQuotaParams = "#{serverURL}/cinder/os-quota-class-sets/#{projectId}"
  novaQuotaParams = "#{serverURL}/nova/os-quota-class-sets/#{projectId}"

  cinderQuota = $http.put cinderQuotaParams, options.cinderQuota
    .then (response) ->
      return response.data
  novaQuota = $http.put novaQuotaParams, options.novaQuota
    .then (response) ->
      return response.data

  $q.all([cinderQuota, novaQuota])
    .then (values) ->
      if values
        callback values
      else
        callback null

$cross.userCreate = ($http, $window, options, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  userURL = "#{serverURL}/users"
  $http.post userURL, options
    .success (data, status, headers) ->
      callback data
    .error (data, status, headers) ->
      if data.status == 409
        toastr.error _("The user name has been used: ") + options.name
      else
        toastr.error _("Failed to create user.")
      callback false

$cross.listProjectGroups = ($http, $window, options, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  projectGroupsURL = "#{serverURL}/#{options.projectId}/project_groups/"
  $http.get projectGroupsURL
    .success (data, status, headers) ->
      callback data
    .error (data, status, headers) ->
      callback false

$cross.listGroupUsers = ($http, $window, $q, options) ->
  deferred = $q.defer()
  serverURL = $window.$CROSS.settings.serverURL
  groupUsers = "#{serverURL}/#{options.groupId}/group_users"
  $http.get groupUsers
    .success (data, status, headers) ->
      deferred.resolve data
    .error (data, status, headers) ->
      deferred.reject data
  return deferred.promise

$cross.createGroupUser = ($http, $window, options, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  groupUserURL = "#{serverURL}/#{options.groupId}/group_users/#{options.userId}"
  $http.post groupUserURL
    .success (data, status, headers) ->
      callback data, status
    .error (data, status, headers) ->
      callback data, status

$cross.createGroupProject = ($http, $window, options, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  groupProjectURL = "#{serverURL}/#{options.projectId}/project_groups/#{options.groupId}"
  $http.post groupProjectURL
    .success (data, status, headers) ->
      callback data, status
    .error (data, status, headers) ->
      callback data, status

$cross.deleteGroupUser = ($http, $window, options, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  groupUserURL = "#{serverURL}/#{options.groupId}/group_users/#{options.userId}"
  $http.delete groupUserURL
    .success (data, status, headers) ->
      callback data, status
    .error (data, status, headers) ->
      callback data, status

$cross.deleteGroup = ($http, $window, options, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  deleteGroupURL = "#{serverURL}/groups/#{options.groupId}"
  $http.delete deleteGroupURL
    .success (data, status, headers) ->
      callback data, status
    .error (data, status, headers) ->
      callback data, status

$cross.createGroup = ($http, $window, options, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  createGroupURL = "#{serverURL}/groups"
  $http.post createGroupURL, options
    .success (data, status, headers) ->
      callback data, status
    .error (data, status, headers) ->
      callback data, status
