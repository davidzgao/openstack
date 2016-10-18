'use strict'

angular.module('Cross.admin.user')
  .controller 'admin.user.UsersCtr', ($scope, $http, $window, $q,
  $cookieStore, $tabs, $templateCache) ->
    $scope.slug = _ 'Users'
    $scope.tabs = [
      {
        title: _('User')
        template: _('user.tpl.html')
        enable: true
      }
    ]

    # Get current user's id from cookie
    $scope.currentUserId = $cookieStore.get('currentUserId')

    $scope.currentTab = 'user.tpl.html'
    $tabs $scope, 'admin.user'

    $scope.sort = {
      reverse: false
    }

    $scope.filters = {
      project: [_('ALL'), 'Admin']
    }

    $scope.selected = 0

    $scope.$watch 'selected', (newVal, oldVal) ->
      if newVal != oldVal
        scopedProject = $scope.filters.project[newVal]
        if scopedProject == 'Admin'
          serverURL = $window.$CROSS.settings.serverURL
          projectParam = "projectsV3?name=admin"
          $http.get "#{serverURL}/#{projectParam}"
            .success (data, status, headers) ->
              adminTenantId = data.data[0].id
              searchOpts = {
                search: true
                searchKey: 'tenantId'
                searchValue: adminTenantId
              }
              $scope.getPagedDataAsync(15, 1, null, searchOpts)
            .error (data, status, headers) ->
              toastr.error _("Failed to get user, try again later!")
         else
           $scope.getPagedDataAsync(15, 1)
    , true

    $scope.showFooter = true
    $scope.unFristPage = false
    $scope.unLastPage = false

    $scope.createAction = _("Create")
    $scope.deleteAction = _("Delete")
    $scope.refesh = _("Refresh")
    $scope.projectAction = _("Assign Project")
    $scope.projectFilters = {
      key: 'project'
      values: [
        {
          verbose: _('ALL')
          value: 'all'
        }
        {
          verbose: _('Admin')
          value: 'admin'
        }
      ]
    }

    $scope.columnDefs = [
      {
        field: "name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.name}}"><a ui-sref="admin.user.userId.overview({userId:item.id})" ng-bind="item[col.field]"></a></div>'
      }
      {
        field: "email",
        displayName: _("E-Mail"),
        cellTemplate: '<div class="ngCellText" data-toggle="tooltip" data-placement="top" title="{{item.email}}">{{item[col.field] | parseNull}}</div>'
      }
      {
        field: "projects",
        displayName: _("Project"),
        cellTemplate: '<div class="ngCellText"><span ng-repeat="project in item.projects" class="list-in-cell">{{project.name}}</span></div>'
        filterTemplate: '<span class="data-filter" filterintable items="datatable.filters.project" action="searchAction()"></span>'
        showFilter: true,
        filters: $scope.projectFilters
      }
      {
        field: "enabled",
        displayName: _("Status"),
        cellTemplate: '<div class="switch-button compute_node_enable" switch-button status="item.condition" action="addition(item.id, item.condition)" verbose="item.ENABLED" enable="item.canDisable"></div>'
      }
    ]

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
    $scope.canAssginProject = 'btn-disable'
    $scope.untouchableSelected = false
    $scope.selectChange = () ->
      $scope.untouchableSelected = false
      untouchableItem = $window.$CROSS.settings.banEditProjects
      if $scope.selectedItems.length == 1
        $scope.singleSelectedItem = $scope.selectedItems[0]
        adminProject = $window.$CROSS.settings.adminProject
        if $scope.singleSelectedItem.project_name == adminProject
          $scope.canAssginProject = 'btn-disable'
        else
          $scope.canAssginProject = 'btn-enable'
        if $scope.selectedItems[0].name in untouchableItem
          $scope.deleteEnableClass = 'btn-disable'
          $scope.untouchableSelected = true
          return
        # NOTE(ZhengYue): Current user which login selected,
        # disable delete action
        if $scope.selectedItems[0].id == $scope.currentUserId
          $scope.deleteEnableClass = 'btn-disable'
          $scope.untouchableSelected = true
        else
          $scope.deleteEnableClass = 'btn-enable'
          $scope.untouchableSelected = false
      else if $scope.selectedItems.length > 1
        $scope.canAssginProject = 'btn-disable'
        $scope.singleSelectedItem = {}
        angular.forEach $scope.selectedItems, (item, index) ->
          if item.name in $window.$CROSS.settings.banEditProjects\
          or item.id == $scope.currentUserId
            $scope.deleteEnableClass = 'btn-disable'
            $scope.untouchableSelected = true
            return
        if $scope.untouchableSelected == false
          $scope.deleteEnableClass = 'btn-enable'
      else
        $scope.singleSelectedItem = {}
        $scope.untouchableSelected = false
        $scope.deleteEnableClass = 'btn-disable'
        $scope.canAssginProject = 'btn-disable'

    $scope.pagingOptions = {
      pageSizes: [15, 25, 50]
      pageSize: 15
      currentPage: 1
    }

    $scope.users = []

    $scope.filter = () ->
      ele = angular.element('.data-filter select')
      $scope.selected = ele.val()

    $scope.triggerEnable = (userId, status) ->
      options =
        userId: userId
      if status == 'on'
        options.enabled = 'false'
        msg = _("Disable user ")
      else
        options.enabled = 'true'
        msg = _("Enabled user ")
      for user in $scope.users
        if user.id == userId
          user.canDisable = false
          break
      $cross.userTrigger $http, $window, options, (statusCode, data) ->
        if statusCode == 200
          for user, index in $scope.users
            if user.id == userId
              user.canDisable = true
              if status == 'on'
                user.enabled = 'false'
                break
              else
                user.enabled = 'true'
                break
          toastr.success(msg + _("success!"))
        else
          toastr.error(msg + _("failed!"))
          for user, index in $scope.users
            if user.id == userId
              user.canDisable = true
              if status == 'on'
                user.enabled = 'true'
                break
              else
                user.enabled = 'false'
                break

    $scope.usersOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      filterAction: $scope.filter
      addition: $scope.triggerEnable
      pageMax: 5
      filters: $scope.filters
    }

    $scope.setPagingData = (pagedData, total) ->
      $scope.users = pagedData
      $scope.totalServerItems = total
      $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
      $scope.usersOpts.data = $scope.users
      $scope.usersOpts.pageCounts = $scope.pageCounts

      if !$scope.$$phase
        $scope.$apply()

    $scope.getPagedDataAsync = (pageSize, currentPage, callback,
    searchOpts) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        dataQueryOpts =
          dataFrom: parseInt(pageSize) * parseInt(currentPage)
          dataTo: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize)

        if searchOpts
          dataQueryOpts.searchKey = searchOpts.searchKey
          dataQueryOpts.searchValue = searchOpts.searchValue
          if searchOpts.search
            dataQueryOpts.search = true
            dataQueryOpts.require_detail = true
        if $scope.searched
          dataQueryOpts.search = true
          dataQueryOpts.searchKey = $scope.searchKey
          dataQueryOpts.searchValue = $scope.searchOpts.val
          dataQueryOpts.require_detail = true

        $cross.listUsers $http, $window, $q, dataQueryOpts,
        (users, total) ->
          $scope.setPagingData(users, total)
          (callback && typeof(callback) == "function") &&\
          callback(users)
      , 300)

    $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    watchCallback = (newVal, oldVal) ->
      $scope.usersOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage,

    $scope.$watch('pagingOptions', watchCallback, true)

    userCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        matched = false
        adminUser = $window.$CROSS.settings.adminUser
        for user in newVal
          if user.name == adminUser
            user.canDisable = false
          if user.id == $scope.currentUserId
            user.canDisable = false
          if $scope.selectedUserId
            if user.id == $scope.selectedUserId
              user.isSelected = true
              $scope.selectedUserId = undefined
          if $scope.selectedUser
            if $scope.selectedUser.id == user.id
              $scope.selectedUser = undefined
              matched = true
          if user.enabled == 'true'
            user.status = 'active'
            user.ENABLED = _ 'Enabled'
            user.condition = 'on'
          else
            user.status = 'stoped'
            user.ENABLED = _ 'Disabled'
            user.condition = 'off'
          if user.isSelected == true
            selectedItems.push user
        if !matched
          if newVal.length > 0 and $scope.selectedUser
            if $scope.selectedUser.enabled == 'true'
              $scope.selectedUser.status = 'active'
              $scope.selectedUser.ENABLED = _ 'Enabled'
              $scope.selectedUser.condition = 'on'
            else
              $scope.selectedUser.status = 'stoped'
              $scope.selectedUser.ENABLED = _ 'Disabled'
              $scope.selectedUser.condition = 'off'
            $scope.users.push $scope.selectedUser
            $scope.selectedUser = undefined

        $scope.selectedItems = selectedItems

    $scope.$watch('users', userCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    $scope.$on('update', (event, detail) ->
      detail.isSelected = true
      delete detail.projectName
      for user, index in $scope.users
        if user.id == detail.id
          detail.projects = $scope.users[index].projects
          $scope.users[index] = detail
          break
      $scope.selectedUser = detail
    )

    $scope.$on('selected', (event, detail) ->
      if $scope.users.length > 0
        for user, index in $scope.users
          if user.id == detail
            $scope.users[index].isSelected = true
          else
            $scope.users[index].isSelected = false
      else
        $scope.selectedUserId = detail
    )

    $scope.refresResource = (resource) ->
      $scope.usersOpts.data = null
      $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                               $scope.pagingOptions.currentPage)

    $scope.deleteUser = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        userId = item.id
        $cross.deleteUser $http, $window, userId, (data, status) ->
          if status == 200
            toastr.options.closebutton = true
            $scope.refresResource()
            msg = _ "Success delete user: "
            toastr.success msg + item.name

  .controller 'admin.user.UserCreateCtr', ($scope, $http, $window, $q, $state) ->
    (new UserCreateModal()).initial($scope, {
      $state: $state,
      $http: $http,
      $window: $window
      $q: $q
    })

    $scope.showProjects = true

    $cross.listProjects $http, $window, $q, {},
    (projects) ->
      avai = []
      adminProject = $window.$CROSS.settings.adminProject
      for project in projects
        # NOTE(ZhengYue): Filter the admin project
        if project.name == adminProject
          continue
        item =
          text: project.name
          value: project.id
        avai.push item
      $scope.modal.fields[5].default = avai
      $scope.form['project'] = avai[0].value

    $scope.$watch 'form', (newVal) ->
      if newVal.isAdmin != null
        if newVal.isAdmin != "normal_user"
          $scope.form.project = null
          $scope.modal.fields[5].type = 'hidden'
          $scope.modal.fields[5].restrictions.required = false
        else
          if $scope.modal.fields[5].default.length > 0
            $scope.form.project = $scope.modal.fields[5].default[0].value
          $scope.modal.fields[5].type = ''
          $scope.modal.fields[5].restrictions.required = true
    , true
    $scope.isAdminCheck = () ->
      value = $scope.modal.fields[4].default[0].value
      $scope.modal.fields[4].default[0].value = !value
      if $scope.modal.fields[4].default[0].value == true
        $scope.form.isAdmin[0] = true
        $scope.modal.fields[5].type = 'hidden'
        $scope.modal.fields[5].restrictions.required = false
      else
        $scope.form.isAdmin[0] = false
        $scope.modal.fields[5].type = ''
        $scope.modal.fields[5].restrictions.required = true

class UserCreateModal extends $cross.Modal
  title: _ "Create User"
  slug: "create_user"

  fields: ->
    ###
     # if you want custome the field, ensure tag: "custom"
     # and add templateUrl
     # if there have more field need custom ,divide
     # them by ng-if at one tempalte or different templates
    ###
    [{
      slug: "name"
      label: _ "User Name"
      tag: "input"
      restrictions:
        required: true
        len: [4, 20]
        func: ($scope, val) ->
          current_field = $scope.modal.fields[2]
          len = current_field.restrictions.len
          if val.length < len[0] or val.length > len[1]
            length_tips_head = _("Length must between ")
            length_tips_value = "#{len[0]} ~ #{len[1]}"
            length_tips_bot = _ " among."
            length_tips = "#{length_tips_head}#{length_tips_value}#{length_tips_bot}"
            $scope.tips['name'] = length_tips
    }
    {
      slug: "email"
      label: _ "E-Mail"
      tag: "input"
      restrictions:
        required: true
        email: true
    }
    {
      slug: "password"
      label: _ "Password"
      tag: "input"
      type: "password"
      restrictions:
        required: true
        len: [6, 20]
        func: ($scope, val) ->
          current_field = $scope.modal.fields[2]
          len = current_field.restrictions.len
          if val.length < len[0] or val.length > len[1]
            length_tips_head = _("Length must between ")
            length_tips_value = "#{len[0]} ~ #{len[1]}"
            length_tips_bot = _ " among."
            length_tips = "#{length_tips_head}#{length_tips_value}#{length_tips_bot}"
            $scope.tips['password'] = length_tips
          else
            if $scope.form.password_confrim
              if val != $scope.form.password_confrim
                diffTip = _ "The two passwords you typed do not match."
                $scope.tips['password_confrim'] = diffTip
                $scope.tips['password'] = diffTip
              else
                $scope.tips['password_confrim'] = ''
                $scope.tips['password'] = ''
    }
    {
      slug: "password_confrim"
      label: _ "Confirm Password"
      tag: "input"
      type: "password"
      restrictions:
        required: true
        len: [6, 20]
        func: ($scope, val) ->
          current_field = $scope.modal.fields[3]
          len = current_field.restrictions.len
          if val.length < len[0] or val.length > len[1]
            length_tips_head = _("Length must between ")
            length_tips_value = "#{len[0]} ~ #{len[1]}"
            length_tips_bot = _ " among."
            length_tips = "#{length_tips_head}#{length_tips_value}#{length_tips_bot}"
            $scope.tips['password_confrim'] = length_tips
          else
            if $scope.form.password
              if val != $scope.form.password
                diffTip = _ "The two passwords you typed do not match."
                $scope.tips['password_confrim'] = diffTip
                $scope.tips['password'] = diffTip
              else
                $scope.tips['password_confrim'] = ''
                $scope.tips['password'] = ''
    }
    {
      slug: "isAdmin"
      label: _ "Admin"
      tag: "select"
      type: ""
      default: [{text: _("super_admin"), value: "super_admin"} \
                ,{text: _("user_admin"), value: "user_admin"} \
                ,{text: _("resource_admin"), value: "resource_admin"} \
                ,{text: _("normal_user"), value: "normal_user"} \
               ]
      restrictions:
        required: true
    }
    {
      slug: "project"
      label: _ "Project"
      tag: "select"
      default: []
      restrictions:
        required: true
    }
    ]
  handle: ($scope, options) ->
    params = {
      name: $scope.form.name
      password: $scope.form.password
      email: $scope.form.email
      enabled: true
      description: ''
      default_project_id: ''
    }
    adminProject = $CROSS.settings.adminProject || 'admin'
    adminRole = $CROSS.settings.adminRole || 'admin'
    memberRole = $CROSS.settings.memberRole || 'Member'
    $state = options.$state
    if !$scope.form.project or $scope.form.isAdmin != "normal_user"
      # Admin user, Get admin project Id
      # TODO(ZhengYue): Optimize: The process so complex for call
      # many API via http, error-prone at each call, and need rollback
      # Take this process to 'backend'.
      projectId = ''
      $cross.listProjects options.$http, options.$window, options.$q,
      {searchKey: 'name', searchValue: adminProject, search: true},
      (data) ->
        if data.length > 0
          projectId = data[0].id
          params.default_project_id = projectId
        else
          return false
        $cross.userCreate options.$http, options.$window, params, (user) ->
          if !user
            $state.go '^'
            return
          if $scope.form.isAdmin == "super_admin"
            adminRole = "admin"
          else if $scope.form.isAdmin == "user_admin"
            adminRole = "user_admin"
          else if $scope.form.isAdmin == "resource_admin"
            adminRole = "resource_admin"
          $cross.listRoles options.$http, options.$window, options.$q,
          {}, (roles) ->
            roleId = ''
            for role in roles[0]
              if role.name == adminRole
                roleId = role.id
              if role.name == "admin"
                superAdminRoleId = role.id
            roleParams = {
              projectId: projectId
              roleId: roleId
              userId: user.id
            }
            $cross.assginRole options.$http, options.$window,
            roleParams, (res, status) ->
              if status == 200
                if adminRole != "admin"
                  roleParams = {
                    projectId: projectId
                    roleId: superAdminRoleId
                    userId: user.id
                  }
                  $cross.assginRole options.$http, options.$window,
                  roleParams, (res, status) ->
                    if status == 200
                      msg = _ "Success create user: "
                      toastr.success msg + user.name
                      options.$state.go "admin.user", {}, {reload: true}
                else 
                  msg = _ "Success create user: "
                  toastr.success msg + user.name
                  options.$state.go "admin.user", {}, {reload: true}
    else
      projectId = $scope.form.project
      params.default_project_id = projectId
      $cross.userCreate options.$http, options.$window, params, (user) ->
        if !user
          $state.go '^'
          return
        $cross.listRoles options.$http, options.$window, options.$q,
        {}, (roles) ->
          roleId = ''
          for role in roles[0]
            if role.name == memberRole
              roleId = role.id
              break
          roleParams = {
            projectId: projectId
            roleId: roleId
            userId: user.id
          }
          $cross.assginRole options.$http, options.$window,
          roleParams, (res, status) ->
            if status == 200
              msg = _ "Success create user: "
              toastr.success msg + user.name
            options.$state.go "admin.user", {}, {reload: true}
    return true
