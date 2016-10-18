'use strict'

angular.module('Cross.admin.project')
  .controller 'admin.project.ProjectActionCtr', ($scope, $http,
  $window, $stateParams) ->
    #Controller for project actions
    projectId = $stateParams.projectId
  .controller 'admin.project.ProjectEditCtr', ($scope, $http,
  $window, $stateParams, $state) ->

    if !$stateParams.projectId or $stateParams.projectId == ''
      $state.go 'admin.project'
    projectId = $stateParams.projectId

    (new ProjectEditModal()).initial($scope,
    {$http: $http, $window: $window})

    $cross.getProject $http, $window, projectId, (project) ->
      $scope.modal.fields[0].defalut = project.name

  .controller 'admin.project.ProjectMemberCtr', ($scope, $http,
  $window, $stateParams, $state, $q, $projectSetUp) ->

    if !$stateParams.projectId or $stateParams.projectId == ''
      $state.go 'admin.project'
    projectId = $stateParams.projectId

    $scope.title = {
      all_user: _("User List")
      member: _("Project Member")
    }
    $scope.tipsNoAvailableUsers = _("No available user")
    $scope.tipsNoUsers = _("No project members")

    (new MemberModal()).initial($scope,
    {$http: $http, $window: $window})

    $scope.note.modal.save = _("Update")

    $cross.listUsers $http, $window, $q, {}, (allUsers) ->
      $cross.listMembership $http, $window, $q, projectId, (oriUsers) ->
        $scope.all_user = []
        user_list = []
        $scope.userList = []
        for user in oriUsers
          if user.roles.length == 0
            continue
          user_list.push user.id
          item =
            text: user.name
            value: user.id
          $scope.userList.push item

        for user in allUsers
          item =
            text: user.name
            value: user.id
          if user.id in user_list
            continue
          else
            $scope.all_user.push item
        $scope.modal.fields[0].default = $scope.all_user
        $scope.modal.fields[1].default = $scope.userList

        $scope.no_available = false
        $scope.no_selected = false
        if $scope.all_user.length == 0
          $scope.no_available = true
        if $scope.userList.length == 0
          $scope.no_selected = true

        $projectSetUp $scope

        $scope.update = () ->
          selectedUser = $scope.modal.fields[1].default
          userAtRight = []
          addedUsers = []
          for user in selectedUser
            userAtRight.push user.value
            if user.value in user_list
              continue
            else
              addedUsers.push user.value
          removedUsers = []
          for user in user_list
            if user in userAtRight
              continue
            else
              removedUsers.push user

          removedSuccess = []
          addedSuccess = []
          angular.forEach removedUsers, (user, index) ->
            options = {
              projectId: projectId,
              userId: user
            }
            $cross.removeRole $http, $window, options, (data, status) ->
              if status == 200
                removedSuccess.push user
              else
                #TODO(ZhengYue): Add tips
                console.log "Failed to remove user"

          $cross.listRoles $http, $window, $q, {}, (roles) ->
            defaultRole = $window.$CROSS.settings.defaultRole
            adminProject = $window.$CROSS.settings.adminProject
            # NOTE(ZhengYue): If the project is 'admin',
            # so the member belong to this project all with
            # 'admin' role.
            $cross.getProject $http, $window, projectId, (data) ->
              if data.name == adminProject
                defaultRole = $window.$CROSS.settings.adminRole
              roleId = ''
              for role in roles[0]
                if role.name == defaultRole
                  roleId = role.id
                  break
              angular.forEach addedUsers, (user, index) ->
                options = {
                  projectId: projectId,
                  roleId: roleId
                  userId: user
                }
                $cross.assginRole $http, $window, options, (data, status) ->
                  if status == 200
                    addedSuccess.push data.id

                  if addedSuccess.length == addedUsers.length
                    toastr.success _ "Success update project!"

          $state.go "admin.project"

  .controller 'admin.project.ProjectGroupCtr', ($scope, $http,
  $window, $stateParams, $state, $q, $projectSetUp) ->

    if !$stateParams.projectId or $stateParams.projectId == ''
      $state.go 'admin.project'
    projectId = $stateParams.projectId

    $scope.title = {
      all_user: _("User List")
      project_groups: _("Group List")
    }

    $projectSetUp $scope

    (new GroupModal()).initial($scope,
    {$http: $http, $window: $window, $state: $state,
    projectId: projectId})

    $cross.listProjectGroups $http, $window, {projectId: projectId}, (data) ->
      request = []
      projectGroups = []
      for item in data
        item.text = item.name
        groupId = item.id
        request.push $cross.listGroupUsers $http, $window, $q, {groupId: groupId}
      $q.all request
        .then (res) ->
          for item, index in data
            item.users = res[index]
            projectGroups.push item
          $scope.modal.steps[0].fields[1].default = projectGroups
          for item in $scope.modal.steps[0].fields[1].default
            for user in item.users
              user.groupId = item.id

    $cross.listUsers $http, $window, $q, {}, (allUsers) ->
      users = []
      for user in allUsers
        if user.nam != 'admin' and user.username != 'admin'
          user.text = user.name
          users.push user
      $scope.modal.steps[0].fields[0].default = users

    $scope.showGroupUsers = (group) ->
      if group.showGroupUsersFlag
        group.showGroupUsersFlag = false
      else
        group.showGroupUsersFlag = true

    $scope.dropComplete = (index, obj, group, flag) ->
      if flag
        options =
          groupId: group.id
          userId: obj.id
        $cross.createGroupUser $http, $window, options, (data, status) ->
          if status == '200' or status == 200
            if not group.users
              group.users = []
            obj.groupId = group.id
            group.users.push obj
            toastr.success _ ["Success to add user(%s) to group(%s)", obj.id, group.id]
          else
            toastr.error _ ["Failed to add user(%s) to group(%s)", obj.id, group.id]
      else
        for group, groupIndex in $scope.modal.steps[0].fields[1].default
          if obj.groupId == group.id
            ind = groupIndex
            for user, userIndex in group.users
              if user.id == obj.id
                options =
                  groupId: group.id
                  userId: user.id
                $cross.deleteGroupUser $http, $window, options, (data, status) ->
                  if status == '200' or status == 200
                    $scope.modal.steps[0].fields[1].default[ind].users.splice(userIndex, 1)
                    toastr.success _ ["Success to remove user(%s) from group(%s)", user.id, group.id]
                  else
                    toastr.error _ ["Failed to remove user(%s) from group(%s)", user.id, group.id]
                return

    $scope.addDeleteIcon = (item) ->
      item.canDelete = true

    $scope.rmDeleteIcon = (item) ->
      item.canDelete = false

    $scope.deleteGroup = (groupId) ->
      options =
        groupId: groupId
      $cross.deleteGroup $http, $window, options, (data, status) ->
        if status == 200 or status == '200'
          for group, index in $scope.modal.steps[0].fields[1].default
            if group.id == groupId
              $scope.modal.steps[0].fields[1].default.splice index, 1
              toastr.success _ ["Success to delete group: %s", groupId]
              return
        else
          toastr.error _ ["Failed to delete group: %s", groupId]

  .controller 'admin.project.ProjectQuotaCtr', ($scope, $http,
  $window, $stateParams, $state, $q) ->
    if !$stateParams.projectId or $stateParams.projectId == ''
      $state.go 'admin.project'
    projectId = $stateParams.projectId

    (new QuotaModal()).initial($scope,
    {$http: $http, $window: $window})

    $scope.systemStatistic = {
      title: _ "Current system available resources"
      note: _ ("When allocate quota, please according to the resource usage of current system.")
    }

    $cross.resourceStatis $http, $window, $q, (data) ->
      $scope.systemStatistic.vcpus = {
        value: data.vcpus - data.vcpus_used
        name: _("Free VCPUS")
      }
      $scope.systemStatistic.ram = {
        value: data.free_ram_mb
        name: _("Free RAM")
        unit: "MB"
      }
      $scope.systemStatistic.disk = {
        value: data.disk_available_least
        name: _("Free Disk")
        unit: "GB"
      }
      $scope.systemStatistic.floatings = {
        value: data.floating_free
        name: _("Free Floating IPs")
      }

    maxQuotaRef = $window.$CROSS.settings.maxQuotaSet

    $scope.showAdvance = false
    $scope.advanceTriggerShow = _ "Show Advance Options"
    $scope.advanceTriggerHide = _ "Hide Advance Options"
    $scope.advTrigge = () ->
      $scope.showAdvance = !$scope.showAdvance

    $cross.getQuota $http, $window, $q, projectId,
    (cinderQuota, novaQuota) ->
      $scope.cinderQuota = cinderQuota
      $scope.novaQuota = novaQuota

      $scope.baseNovaQuotaSet = [
        {
          name: _("CPU Cores")
          item: 'cores'
          max: maxQuotaRef.cores
          current: $scope.novaQuota.cores
        }
        {
          name: _("Instance Counts")
          item: 'instances'
          max: maxQuotaRef.instances
          current: $scope.novaQuota.instances
        }
        {
          name: _("Ram")
          item: 'ram'
          max: maxQuotaRef.ram
          current: $scope.novaQuota.ram
          unit: 'MB'
        }
        {
          name: _("Floating IPs")
          item: 'floating_ips'
          max: maxQuotaRef.floating
          current: $scope.novaQuota.floating_ips
        }
      ]
      $scope.baseCinderQuotaSet = [
        {
          name: _("Volume Counts")
          item: 'volumes'
          max: maxQuotaRef.volumes
          current: $scope.cinderQuota.volumes
        }
        {
          name: _("Volume Capacity")
          item: 'gigabytes'
          max: maxQuotaRef.volume_size
          current: $scope.cinderQuota.gigabytes
          unit: 'GB'
        }
      ]

      $scope.advanceNovaQuotaSet = [
        {
          name: _("Key Pairs")
          max: maxQuotaRef.key_paris
          item: 'key_pairs'
          current: $scope.novaQuota.key_pairs
        }
        {
          name: _("Security Groups")
          max: maxQuotaRef.security_groups
          item: 'security_groups'
          current: $scope.novaQuota.security_groups
        }
      ]

      $scope.advanceCinderQuotaSet = [
        {
          name: _("Volume Snapshots")
          max: maxQuotaRef.volume_snapshots
          item: 'snapshots'
          current: $scope.cinderQuota.snapshots
        }
      ]

      $scope.checkInput = (name, type, index, level) ->
        if type[name] == null or !type[name]
          if type == novaQuota
            $scope.novaQuota[name] = 0
            $scope["#{level}NovaQuotaSet"][index].current = 0
          else
            $scope.cinderQuota[name] = 0
            $scope["#{level}CinderQuotaSet"][index].current = 0

      $scope.note.modal.save = _ "Update"
      $scope.update = () ->
        # NOTE(ZhengYue): The ephemeral and disk can't update
        delete $scope.novaQuota['OS-FLV-EXT-DATA:ephemeral']
        delete $scope.novaQuota['disk']
        delete $scope.novaQuota['id']
        delete $scope.cinderQuota['OS-FLV-EXT-DATA:ephemeral']
        delete $scope.cinderQuota['disk']
        delete $scope.cinderQuota['id']
        options = {
          novaQuota:
            $scope.novaQuota
          cinderQuota:
            $scope.cinderQuota
        }
        $cross.updateQuota $http, $window, $q, projectId, options,
        (data) ->
          if data
            toastr.success(_('Success to update quota!'))
          else
            toastr.success(_('Failed to update quota!'))

        $state.go 'admin.project'

class ProjectEditModal extends $cross.Modal
  title: _ "Edit Project"
  slug: "update_project"

  fields: ->
    [{
      slug: "name"
      label: _ "Project Name"
      tag: "input"
      default: ''
      restrictions:
        required: true
    }, {
      slug: "description"
      label: _("Description")
      tag: "textarea"
      restrictions:
        required: false
    }, {
      slug: "enabled"
      label: _("Enabled")
      tag: "input"
      type: "checkbox-list"
      default: [{text: _("Enable"), value: true}]
      restrictions:
        required: false
    }]

class MemberModal extends $cross.Modal
  title: _ "Member Manage"
  slug: "member_manage"

  fields: ->
    [{
      slug: "user_list"
      label: _ "User List"
      tag: "select"
      default: []
      restrictions:
        required: false
    }, {
      slug: "member"
      label: _("Project Members")
      tag: "select"
      default: []
      restrictions:
        required: false
    }]

class GroupModal extends $cross.Modal
  title: _ "Group Management"
  slug: "group_management"
  single: false
  steps: ['groupUser', 'group']
  parallel: true

  step_groupUser: ->
    name: _ "Relationship Management"
    fields:
      [{
        slug: "user_list"
        label: _ "User List"
        tag: "select"
        default: []
        restrictions:
          required: false
      }, {
        slug: "member"
        label: _("Project Members")
        tag: "select"
        default: []
        restrictions:
          required: false
      }]

  step_group: ->
    name: _ "Group Created"
    fields:
      [{
        slug: "name"
        label: _ "Group Name"
        tag: "input"
        default: []
        restrictions:
          required: true
      }]

  handle: ($scope, options)->
    $http = options.$http
    $window = options.$window
    $state = options.$state
    projectId = options.projectId
    params =
      name: $scope.form['group']['name']
      domain_id: "default"
    $cross.createGroup $http, $window, params, (group) ->
      groupId = group.id
      options =
        groupId: groupId
        projectId: projectId
      $cross.createGroupProject $http, $window, options, (groupProject, status) ->
        if status == '200' or status == 200
          group.text = group.name
          $scope.modal.steps[0].fields[1].default.push group
          toastr.success _ ["Success to create group: %s", groupId]
          $state.go 'admin.project.projectId.group', {projectId: projectId}, {reload: true}
        else
          $scope.modal.modalLoading = false
          toastr.error _ ["Failed to create group: %s", groupId]

class QuotaModal extends $cross.Modal
  title: _ "Quota Manage"
  slug: "quota_manage"

  fields: ->
    [{
      slug: "user_list"
      label: _ "User List"
      tag: "select"
      default: []
      restrictions:
        required: false
    }, {
      slug: "member"
      label: _("Project Members")
      tag: "select"
      default: []
      restrictions:
        required: false
    }
    ]
