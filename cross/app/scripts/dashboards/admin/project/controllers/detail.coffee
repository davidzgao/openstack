'use strict'

angular.module 'Cross.admin.project'
  .controller 'admin.project.ProjectDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state, $selected, $detailShow,
  $updateDetail, $watchDeleted) ->
    $scope.detailItem = {
      info: _("Detail Info")
      item: {
        name: _("Name")
        id: _("ID")
        desc: _("Description")
        enable: _("Status")
      }
      userName: _ ("User Name")
      emailAddress: _("E-Mail Address")
      defaultEmail: "<" + _("null") + ">"
      memberInfo: _("Project Member")
      memberName: _("Member Name")
      quotaUsage: _("Quota Usage")
      memberNoneTips: _("None Members")
      edit: _("Edit")
      save: _("Save")
      cancel: _("Cancel")
      enable: _("Enable")
      disable: _("Disable")
      quotaItem: {
        cpu: _('CPU Cores')
        instance: _('Instance Counts')
        memory: _('Ram')
        floating: _('FloatingIP')
        disk: _('Volume Counts')
        disk_capacity: _('Volume Capacity')
      }
    }
    $scope.inputInValidate = false

    $scope.ori_project_name = ''
    $scope.ori_project_desc = ''
    $scope.ori_project_enabled = ''

    projectOptions =
      dashboard: 'admin'
      slug: 'proj'
      tabs: [
        {
          name: _('Overview')
          url: 'admin.project.projId.overview'
          available: true
        }
      ]

    projectDetail = new ProjectDetail(projectOptions)
    projectDetail.init($scope, {
      $http: $http
      $q: $q
      $window: $window
      $state: $state
      $stateParams: $stateParams
      $selected: $selected
      $detailShow: $detailShow
      $updateDetail: $updateDetail
      $watchDeleted: $watchDeleted
    })

    $scope.canEdit = 'btn-enable'

    $scope.inEdit = 'fixed'
    $scope.editing = false

    $scope.edit = () ->
      if $scope.canEdit == 'btn-disable'
        return false
      if $scope.inEdit == 'fixed'
        $scope.inEdit = 'editing'
        $scope.editing = true
      else
        $scope.inEdit = 'fixed'
        $scope.editing = false
        return

    $scope.cancel = () ->
      $scope.inputInValidate = false
      $scope.inputTips = ""
      $scope.inEdit = 'fixed'
      $scope.editing = false
      $scope.project_detail.name = $scope.ori_project_name
      $scope.project_detail.description = $scope.ori_project_desc

    $scope.triggerEnable = () ->
      if $scope.project_detail.enabled == 'true'
        $scope.project_detail.enabled = 'false'
      else
        $scope.project_detail.enabled = 'true'

    $scope.checkName = () ->
      name = $scope.project_detail.name
      if name
        if name.length < 5 or name.length > 20
          $scope.validate = 'ng-invalid'
          $scope.inputInValidate = true
          $scope.inputTips = _ "Length must between 5 and 20."
        else
          $scope.validate = ''
          $scope.inputInValidate = false
      else
        $scope.inputInValidate = true
        $scope.inputTips = _ "Cannot be empty."

    $scope.save = () ->
      $scope.checkName()
      if $scope.inputInValidate
        $scope.checkName()
      else
        $scope.inEdit = 'fixed'
        $scope.editing = false

        options = {
          projectId: $scope.currentId
          name: $scope.project_detail.name
          description: $scope.project_detail.description
        }
        if $scope.project_detail.name == $scope.ori_project_name\
        and $scope.project_detail.description == $scope.ori_project_desc
          return
        $cross.updateProject $http, $window, options, (project) ->
          if project.enabled == true
            project.enabled = 'true'
            project.status = _("Enabled")
            project.statusClass = "ACTIVE"
            $scope.ori_project_enabled = 'true'
          else
            project.enabled = 'false'
            project.status = _("Disabled")
            project.statusClass = "SHUTOFF"
            $scope.ori_project_enabled = 'false'
          if project.description
            if project.description == 'null' or project.description == ''
              project.description = ''
              project.desc = "<#{$scope.none}>"
              $scope.ori_project_desc = ''
            else
              project.desc = project.description
              $scope.ori_project_desc = project.desc
          else
            project.description = ''
            project.desc = "<#{$scope.none}>"
            $scope.ori_project_desc = project.desc
          $scope.project_detail = project
          $scope.$emit('update', project)
          toastr.success _("Success update project!")

    $scope.project_detail_tabs = [
      {
        name: _('Overview'),
        url: 'admin.project.projId.overview',
        available: true
      }
    ]

class ProjectDetail extends $cross.DetailView
  customScope: ($scope, options) ->
    return
  getDetail: ($scope, options) ->
    $window = options.$window
    $http = options.$http
    $q = options.$q

    $scope.none = _ "None"
    serverUrl = $window.$CROSS.settings.serverURL
    $cross.getProject $http, $window, $scope.currentId, (project) ->
      adminProject = $window.$CROSS.settings.adminProject
      $scope.ori_project_name = project.name
      $scope.ori_project_enabled = project.enabled
      if project.description
        if project.description == 'null' or project.description == ''
          project.description = ''
          project.desc = "<#{$scope.none}>"
          $scope.ori_project_desc = ''
        else
          project.desc = project.description
          $scope.ori_project_desc = project.desc
      else
        project.description = ''
        project.desc = "<#{$scope.none}>"
        $scope.ori_project_desc = project.desc
      if project.name == adminProject
        $scope.canEdit = 'btn-disable'
      if project.enabled == 'true'
        project.statusClass = "ACTIVE"
        project.status = _("Enabled")
      else
        project.statusClass = "SHUTOFF"
        project.status = _("Disabled")
      $scope.project_detail = project

    $scope.getProjectUsers = () ->
      $cross.listMembership $http, $window, $q, $scope.currentId,
      (members) ->
        $scope.project_members = members

    getQuota = (projectId) ->
      serverUrl = $window.$CROSS.settings.serverURL
      novaQuotaUrl = "#{serverUrl}/nova/os-quota-sets/#{projectId}?usage=true"
      cinderQuotaUrl = "#{serverUrl}/cinder/os-quota-sets/#{projectId}?usage=true"
      novaQuota = $http.get(novaQuotaUrl)
        .then (response) ->
          return response.data
      cinderQuota = $http.get(cinderQuotaUrl)
        .then (response) ->
          return response.data

      $scope.novaQuota = {}
      $scope.cinderQuota = {}
      $q.all([novaQuota, cinderQuota])
        .then (values) ->
          novaQuota = values[0]
          cinderQuota = values[1]
          $scope.novaQuota = novaQuota
          $scope.cinderQuota = cinderQuota

    $scope.getProjectUsers()
    getQuota($scope.currentId)
