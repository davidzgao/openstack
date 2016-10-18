'use strict'

angular.module('Cross.admin.project')
  .controller 'admin.project.ProjectsCtr', ($scope, $http, $window,
  $q, $interval, $state, $log, $tabs) ->
    $scope.slug = _ 'Projects'
    $scope.tabs = [
      {
        title: _('Project')
        template: _('project.tpl.html')
        enable: true
      }
    ]

    $scope.currentTab = 'project.tpl.html'
    $tabs $scope, 'admin.project'

    $scope.sort = {
      reverse: false
    }

    $scope.showFooter = true
    $scope.unFristPage = false
    $scope.unLastPage = false

    $scope.free = _('None')
    $scope.createAction = _("Create")
    $scope.deleteAction = _("Delete")
    $scope.refesh = _("Refresh")

    $scope.columnDefs = [
      {
        field: "name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText enableClick" ng-click="detailShow(item.id)" data-toggle="tooltip" data-placement="top" title="{{item.name}}"><a ui-sref="admin.project.projId.overview({projId:item.id})" ng-bind="item[col.field]"></a></div>'
      }
      {
        field: "description",
        displayName: _("Description"),
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]"></div>'
      }
      {
        field: "enabled",
        disabled: true,
        displayName: _("Status"),
        cellTemplate: '<div class="switch-button compute_node_enable" switch-button status="item.condition" action="addition(item.id, item.condition)" verbose="item.ENABLED" enable="item.canDisable"></div>'
      }
    ]

    $scope.more = _("More Action")

    $scope.moreActions = [
      {
        action: 'member',
        verbose: _('Member'),
        enable: 'disabled'
        actionTemplate: '<a ui-sref="admin.project.projectId.member({projectId: singleSelectedItem.id})" ng-class="action.enable" id="{{action.action}}"><i ng-class="action.action"></i>{{action.verbose}}</a>'
        actionDisableTemplate: '<a ng-class="action.enable"><i ng-class="action.action"></i>{{action.verbose}}</a>'
      }
      {
        action: 'member'
        verbose: _('Groups')
        enable: 'disabled'
        actionTemplate: '<a ui-sref="admin.project.projectId.group({projectId: singleSelectedItem.id})" ng-class="action.enable" id="{{action.action}}"><i ng-class="action.action"></i>{{action.verbose}}</a>'
        actionDisableTemplate: '<a ng-class="action.enable"><i ng-class="action.action"></i>{{action.verbose}}</a>'
      }
      {
        action: 'quota',
        verbose: _('Quota'),
        enable: 'disabled'
        actionTemplate: '<a ui-sref="admin.project.projectId.quota({projectId: singleSelectedItem.id})" ng-class="action.enable" id="{{action.action}}"><i ng-class="action.action"></i>{{action.verbose}}</a>'
        actionDisableTemplate: '<a ng-class="action.enable"><i ng-class="action.action"></i>{{action.verbose}}</a>'
      }
    ]

    # The options for search projects
    $scope.searchKey = 'name'
    $scope.search = (key, value) ->
      pageSize = $scope.pagingOptions.pageSize
      if value == undefined or value == ''
        if $scope.searched
          $scope.pagingOptions.currentPage = 1
          $scope.refresResource()
          $scope.searched = false
          return
        else
          return
      if $scope.noSearchMatch
        if $scope.oldSearchValue
          if value.length > $scope.oldSearchValue.length
            return
      $scope.oldSearchValue = value
      $scope.pagingOptions.currentPage = 1
      currentPage = 1
      $scope.searched = true
      $scope.getPagedDataAsync pageSize, currentPage, (projects) ->
        if projects.length == 0
          $scope.noSearchMatch = true
        else
          $scope.noSearchMatch = false

    $scope.searchOpts = {
      search: () ->
        $scope.search($scope.searchKey, $scope.searchOpts.val)
      showSearch: true
    }

    $scope.AllSelectedItems = false
    $scope.NoSelectedItems = true

    $scope.singleSelectedItem = {}
    $scope.selectedItems = []

    $scope.deleteEnableClass = 'btn-disable'
    $scope.untouchableSelected = false
    $scope.selectChange = () ->
      $scope.untouchableSelected = false
      untouchableItem = $window.$CROSS.settings.banEditProjects
      if untouchableItem == undefined
        $log.error("Configuration Error: Please set admin project
           name in banEditProjects at config file!")
      if $scope.selectedItems.length == 1
        $scope.singleSelectedItem = $scope.selectedItems[0]
        if $scope.selectedItems[0].name in untouchableItem
          $scope.deleteEnableClass = 'btn-disable'
          $scope.untouchableSelected = true
          angular.forEach $scope.moreActions, (action, index) ->
            action.enable = 'enabled'
        else
          $scope.deleteEnableClass = 'btn-enable'
          $scope.untouchableSelected = false
          angular.forEach $scope.moreActions, (action, index) ->
            action.enable = 'enabled'
      else if $scope.selectedItems.length > 1
        angular.forEach $scope.moreActions, (action, index) ->
          action.enable = 'disabled'
        $scope.singleSelectedItem = {}
        angular.forEach $scope.selectedItems, (item, index) ->
          if item.name in $window.$CROSS.settings.banEditProjects
            $scope.deleteEnableClass = 'btn-disable'
            $scope.untouchableSelected = true
            return
        if $scope.untouchableSelected == false
          $scope.deleteEnableClass = 'btn-enable'
      else
        $scope.singleSelectedItem = {}
        angular.forEach $scope.moreActions, (action, index) ->
          action.enable = 'disabled'
        $scope.untouchableSelected = false
        $scope.deleteEnableClass = 'btn-disable'

    # Disable the action link when none user selected
    getElement = $interval(() ->
      memberLink = angular.element("#member")
      quotaLink = angular.element("#quota")
      memberLink.bind 'click', ->
        return false
      quotaLink.bind 'click', ->
        return false
      if memberLink.length and quotaLink.length
        $interval.cancel(getElement)
    , 300)

    $scope.$watch 'singleSelectedItem', (newVal, oldVal) ->
      memberLink = angular.element("#member")
      quotaLink = angular.element("#quota")

      if newVal.id
        memberLink.unbind 'click'
        quotaLink.unbind 'click'
      else
        memberLink.bind 'click', ->
          return false
        quotaLink.bind 'click', ->
          return false
    , true

    $scope.pagingOptions = {
      pageSizes: [15, 25, 50]
      pageSize: 15
      currentPage: 1
    }

    $scope.projects = []

    projectCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        adminProject = $window.$CROSS.settings.adminProject
        for project in newVal
          if $scope.selectedProjectId
            if project.id == $scope.selectedProjectId
              project.isSelected = true
              $scope.selectedProjectId = undefined
          if project.name == adminProject
            project.canDisable = false
          if not project.description
            project.description = 'null'
          if project.enabled == 'true'
            project.status = 'active'
            project.ENABLED = _ 'Enabled'
            project.condition = 'on'
          else
            project.status = 'stoped'
            project.ENABLED = _ 'Disabled'
            project.condition = 'off'
          if project.description == 'null'
            project.description = "<#{$scope.free}>"
          if project.isSelected == true
            selectedItems.push project

        $scope.selectedItems = selectedItems

    $scope.triggerEnable = (projectId, status) ->
      options =
        projectId: projectId
      if status == 'on'
        options.enabled = 'false'
        msg = _("Disable project ")
      else
        options.enabled = 'true'
        msg = _("Enabled project ")
      for project in $scope.projects
        if project.id == projectId
          project.canDisable = false
          break
      $cross.projectTrigger $http, $window, options, (statusCode, data) ->
        if statusCode == 200
          toastr.success(msg + _("success!"))
          for project, index in $scope.projects
            project.canDisable = true
            if project.id == projectId
              if status == 'on'
                project.enabled = 'false'
                break
              else
                project.enabled = 'true'
                break
        else
          toastr.error(msg + _("failed!"))
          for project, index in $scope.projects
            if project.id == projectId
              project.canDisable = true
              if status == 'on'
                project.enabled = 'true'
                break
              else
                project.enabled = 'false'
                break

    $scope.projectsOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      pageMax: 5
      addition: $scope.triggerEnable
    }

    $scope.setPagingData = (pagedData, total) ->
      $scope.projects = pagedData
      $scope.totalServerItems = total
      $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
      $scope.projectsOpts.data = $scope.projects
      $scope.projectsOpts.pageCounts = $scope.pageCounts

      if !$scope.$$phase
        $scope.$apply()

    $scope.getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        dataQueryOpts =
          dataFrom: parseInt(pageSize) * parseInt(currentPage)
          dataTo: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize) - 1

        if $scope.searched
          dataQueryOpts.search = true
          dataQueryOpts.searchKey = $scope.searchKey
          dataQueryOpts.searchValue = $scope.searchOpts.val
          dataQueryOpts.require_detail = true
        $cross.listProjects $http, $window, $q, dataQueryOpts,
        (projects, total) ->
          $scope.setPagingData(projects, total)
          (callback && typeof(callback) == "function") && callback(projects)
      , 500)

    $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    watchCallback = (newVal, oldVal) ->
      $scope.projectsOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage,

    $scope.$watch('pagingOptions', watchCallback, true)

    $scope.$watch('projects', projectCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    $scope.deleteProject = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        projectId = item.id
        $cross.deleteProject $http, $window, projectId, (res, status) ->
          if status == 200
            toastr.success(_("Success delete project: ") + item.name)
            $state.go "admin.project", {}, {reload: true}
          else
            toastr.error(_("Failed delete project: ") + item.name)

    $scope.$on('selected', (event, detail) ->
      if $scope.projects.length > 0
        for project, index in $scope.projects
          if project.id == detail
            $scope.projects[index].isSelected = true
          else
            $scope.projects[index].isSelected = false
      else
        $scope.selectedProjectId = detail
    )

    $scope.$on('update', (event, detail) ->
      for project in $scope.projects
        if project.id == detail.id
          project.name = detail.name
          project.description = detail.description
          break
    )

    $scope.refresResource = (resource) ->
      $scope.projectsOpts.data = null
      $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                               $scope.pagingOptions.currentPage)

  .controller 'admin.project.ProjectCreateCtr', ($scope, $http, $window, $q, $state, $projectSetUp) ->
    (new ProjectCreateModal()).initial($scope,
      {$http: $http, $window: $window, $q: $q, $state: $state})

    $scope.title = {
      all_user: _("User List")
      member: _("Project Member")
      no_user: _("No project members")
      no_available: _("No available user")
    }

    $scope.createTips = {
      base_tips: _("From here you can create a new project to organize users.")
      member_tips: _("From this step you can assgin member for new project.")
    }

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

    $scope.all_user = []
    user_list = []
    $scope.userList = []
    $cross.listUsers $http, $window, $q, {}, (allUsers) ->
      for user in allUsers
        item =
          text: user.name
          value: user.id
        $scope.all_user.push item

    $scope.no_available = false
    $scope.no_selected = false
    if $scope.all_user.length == 0
      $scope.no_available = true
    if $scope.userList.length == 0
      $scope.no_selected = true

    $projectSetUp $scope

    $scope.showAdvance = false
    $scope.advanceTriggerShow = _ "Show Advance Options"
    $scope.advanceTriggerHide = _ "Hide Advance Options"
    $scope.advTrigge = () ->
      $scope.showAdvance = !$scope.showAdvance

    maxQuotaRef = $window.$CROSS.settings.maxQuotaSet

    $scope.novaQuota = undefined
    $scope.cinderQuota = undefined
    $scope.novaDefaultQuota = undefined
    $scope.cinderDefaultQuota = undefined
    $cross.getQuota $http, $window, $q, 'default',
    (cinderQuota, novaQuota) ->
      $scope.cinderDefaultQuota = cinderQuota
      $scope.novaDefaultQuota = novaQuota
      $scope.cinderQuota = cinderQuota
      $scope.novaQuota = novaQuota

      $scope.baseNovaQuotaSet = null
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
      $scope.baseCinderQuotaSet = null
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

      $scope.advanceNovaQuotaSet = null
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
      $scope.advanceCinderQuotaSet = null
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

class ProjectCreateModal extends $cross.Modal
  title: _ "Create Project"
  slug: "create_project"
  single: false
  steps: ['base', 'member', 'quota']
  parallel: true

  step_base: ->
    name: _ "Project Info"
    fields:
      [{
        slug: "name"
        label: _("Name")
        tag: "input"
        restrictions:
          required: true
          len: [4, 20]
      },{
        slug: "description"
        label: _("Description")
        tag: "textarea"
        restrictions:
          required: false
      },{
        slug: "enabled"
        label: _("Enabled")
        tag: "input"
        type: "checkbox-list"
        default: [{text: _("Enable"), value: true}]
        restrictions:
          required: false
      }]

  step_member: ->
    name: _ "Member Manage"
    fields:
      [{
        slug: "user_list"
        label: _("User List")
        tag: "select"
        default: []
        restrictions:
          required: false
      },{
        slug: "member"
        label: _("Project Member")
        tag: "select"
        default: []
        restrictions:
          required: false
      }]

  step_quota: ->
    name: _ "Quota Manage"
    fields:
      [{
        slug: "name"
        label: _("Name")
        tag: "input"
        restrictions:
          required: false
      },{
        slug: "description"
        label: _("Description")
        tag: "textarea"
        restrictions:
          required: false
      }]

  handle: ($scope, options) ->
    # TODO(ZhengYue): Tips and error handler
    base = $scope.form.base
    if base.enabled
      base.enabled = base.enabled[0]
    else
      base.enabled = false
    $cross.createProject options.$http, options.$window, base,
    (data, status) ->
      projectId = data.id
      errorMsg = _ "Failed to create project!"
      if status == 200
        toastr.success _ "Success create project!"
        options.$state.go 'admin.project', {}, {reload: true}
      else if status == 409
        reason = _ "Project's name already exist."
        msg = "#{errorMsg} #{reason}"
        toastr.error msg
        options.$state.go 'admin.project', {}, {reload: true}
        return
      else
        toastr.error errorMsg
        options.$state.go 'admin.project', {}, {reload: true}
        return
      if $scope.userList.length > 0
        defaultRole = options.$window.$CROSS.settings.defaultRole
        defaultRoleId = ''
        $cross.listRoles options.$http, options.$window, options.$q, {},
        (data) ->
          for role in data[0]
            if role.name == defaultRole
              defaultRoleId = role.id
              break

          params = {
            projectId: projectId
            roleId: defaultRoleId
          }

          angular.forEach $scope.userList, (user, index) ->
            params.userId = user.value
            $cross.assginRole options.$http, options.$window, params,
            (data, status) ->
              toastr.options.closebutton = true

      # Update the default quota for project
      delete $scope.novaQuota['OS-FLV-EXT-DATA:ephemeral']
      delete $scope.novaQuota['disk']
      delete $scope.novaQuota['id']
      delete $scope.cinderQuota['OS-FLV-EXT-DATA:ephemeral']
      delete $scope.cinderQuota['disk']
      delete $scope.cinderQuota['id']
      params = {
        novaQuota:
          $scope.novaQuota
        cinderQuota:
          $scope.cinderQuota
      }
      $cross.updateQuota options.$http, options.$window,
      options.$q, projectId, params, (data) ->
        toastr.options.closebutton = true

      return true
