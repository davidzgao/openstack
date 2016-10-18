'use strict'

angular.module 'Cross.admin.user'
  .controller 'admin.user.UserDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state, $compile, $rootScope, $log) ->
    $scope.detailItem = {
      info: _("Detail Info")
      item: {
        name: _("Name")
        id: _("ID")
        email: _("E-Mail")
        enable: _("Status")
      }
      primary_project: _("Primary Project")
      edit: _("Edit")
      save: _("Save")
      cancel: _("Cancel")
      enable: _("Enable")
      disable: _("Disable")
      is_admin: _("Admin")
      resetPassword: _("Reset Password")
    }

    $scope.ori_user_name = ''
    $scope.ori_user_email = ''
    $scope.ori_user_enabled = ''

    $scope.canEdit = 'btn-enable'

    $scope.currentId = $stateParams.userId
    $scope.checkSelect = () ->
      $scope.$emit("selected", $scope.currentId)

    $scope.checkSelect()

    $scope.inEdit = 'fixed'
    $scope.editing = false

    $scope.joinProject = true

    $scope.item = [$scope.currentId]
    adminProject = $window.$CROSS.settings.adminProject

    $scope.edit = () ->
      if $scope.inEdit == 'fixed'
        $scope.inEdit = 'editing'
        $scope.editing = true
      else
        $scope.inEdit = 'fixed'
        $scope.editing = false
        return

    $scope.cancel = () ->
      $scope.nameInValidate = false
      $scope.emailInValidate = false
      $scope.nameTips = ''
      $scope.emailTips = ''
      $scope.user_detail.name = $scope.ori_user_name
      $scope.user_detail.email = $scope.ori_user_email
      $scope.user_detail.is_admin = $scope.ori_is_admin
      $scope.inEdit = 'fixed'
      $scope.editing = false

    $scope.triggerEnable = () ->
      if $scope.user_detail.enabled == 'true'
        $scope.user_detail.enabled = 'false'
      else
        $scope.user_detail.enabled = 'true'

    $scope.checkName = () ->
      name = $scope.user_detail.name
      if name
        if name.length < 4 or name.length > 20
          $scope.usernameValidate = 'ng-invalid'
          $scope.nameInValidate = true
          $scope.nameTips = _ "Length must between 4 and 20."
        else
          $scope.usernameValidate = ''
          $scope.nameInValidate = false
      else
        $scope.nameInValidate = true
        $scope.nameTips = _ "Cannot be empty."

    $scope.checkEmail = () ->
      email = $scope.user_detail.email
      emailRe = /\S+@\S+\.\S+/
      if email
        if not emailRe.test(email)
          $scope.emailValidate = 'ng-invalid'
          $scope.emailInValidate = true
          $scope.emailTips = _ "Email format error."
        else
          $scope.emailInValidate = false
          $scope.emailValidate = ''
      else
        $scope.emailInValidate = true
        $scope.emailTips = _ "Cannot be empty."

    $scope.notify = (data) ->
      $scope.$emit("update", data)

    $scope.checkJoin = (target) ->
      if target
        $scope.selectedProject = target.this.selectedProject
      else
        return
      $log.debug "Projects of current user belongs: " +\
      $scope.projectsUserBelongs.length
      for project in $scope.projectsUserBelongs
        if project.id == $scope.selectedProject.id
          $scope.joinProject = false
          break

    $scope.checkProject = () ->
      if $scope.singleProject and !$scope.user_detail.is_admin
        for project, index in $scope.allProjects
          if project.name == adminProject
            $scope.adminProject = $scope.allProjects.splice(index, 1)
            break
      return

    $scope.save = () ->
      # TODO(ZhengYue): Complex function, optimize it.
      # NOTE(ZhengYue): In this function, only set user's primary
      # project, if user don't belong to current primary project,
      # only make user join in, not remove this user from previous
      # primary project. Because this belong 'project manger',
      # at other function.
      $scope.checkName()
      $scope.checkEmail()
      $scope.checkJoin()
      if $scope.nameInValidate or $scope.emailInValidate
        $scope.checkName()
        $scope.checkEmail()
      else
        $scope.inEdit = 'fixed'
        $scope.editing = false

        adminProject = $CROSS.settings.adminRole || 'admin'
        adminRole = $window.$CROSS.settings.adminRole || 'admin'
        memberRole = $window.$CROSS.settings.defaultRole || 'Member'
        if !adminRole or !memberRole
          $log.error "Error of the config file at 'adminRole'\
                     or 'memberRole'!"
        $cross.listRoles $http, $window, $q, {}, (roles) ->
          for role in roles[0]
            if role.name == adminRole
              $scope.adminRoleId = role.id
            if role.name == memberRole
              $scope.memberRoleId = role.id

          if $scope.user_detail.is_admin != $scope.ori_is_admin
            roleOptions = {
              projectId: $scope.adminProjectId
              roleId: $scope.adminRoleId
              userId: $scope.currentId
            }
            if $scope.user_detail.is_admin
              adminJoined = true
              # Set user to be admin!
              $cross.assginRole $http, $window, roleOptions,
              (data, status) ->
                if status != 200
                  $log.error "Failed to assgin user role!"
                else
                  $log.info "Success to assgin admin role!"
            else
              # Remove the admin role from current user
              $cross.removeRole $http, $window, roleOptions,
              (data, status) ->
                if status != 200
                  $log.error "Failed to remove user admin role!"
                else
                  $log.info "Success to remove user admin role!"

          if (typeof $scope.selectedProject == 'string')
            newProject = $scope.selectedProject
          else
            newProject = $scope.selectedProject.id

          if $scope.user_detail.is_admin
            newProject = $scope.adminProjectId

          options = {
            userId: $scope.currentId
            name: $scope.user_detail.name
            email: $scope.user_detail.email
            tenantId: newProject
          }
          if $scope.user_detail.name == $scope.ori_user_name\
          and $scope.user_detail.email == $scope.ori_user_email\
          and $scope.user_detail.tenantId == $scope.selectedProject
            return
          if $scope.joinProject and !adminJoined
            $log.debug "This user need join the\
                        selected project"
            joinRoleOptions = {
              projectId: newProject
              roleId: $scope.memberRoleId
              userId: $scope.currentId
            }
            $cross.assginRole $http, $window, joinRoleOptions,
            (data, status) ->
              if status != 200
                $log.error "Failed to join project by member role!"
              else
                $log.info "Success to join selected project!"

          $cross.updateUser $http, $window, options, (data, status) ->
            user = data.user
            user.is_admin = $scope.user_detail.is_admin
            if user.is_admin
              $scope.ori_is_admin = true
              user.isAdmin = _('Yes')
              user.projectName = adminProject
            else
              $scope.ori_is_admin = false
              user.isAdmin = _('No')
              for project in $scope.allProjects
                if project.id == user.tenantId
                  user.projectName = project.name
                  break
            if user.enabled == true
              user.enabled = 'true'
              user.statusClass = "ACTIVE"
              user.status = _("Enabled")
            else
              user.enabled = 'false'
              user.statusClass = "SHUTOFF"
              user.status = _("Disabled")
            # (NOTE)ZhengYue: Deep copy to create a duplicate,
            # avoid pollute data between two scopes.
            initialUser = angular.copy(user)
            $scope.notify(initialUser)
            $scope.user_detail = user
            toastr.success _("Success update user!")

    $scope.getUser = () ->
      $cross.getUser $http, $window, $scope.currentId, (user) ->
        adminUser = $window.$CROSS.settings.adminUser
        if user.email == "null"
          user.email = ""
        $scope.ori_user_name = user.name
        $scope.ori_user_email = user.email
        $scope.ori_user_enabled = user.enabled
        if user.name == adminUser
          $scope.canEdit = 'btn-disable'
        if user.enabled == 'true'
          user.statusClass = "ACTIVE"
          user.status = _("Enabled")
        else
          user.statusClass = "SHUTOFF"
          user.status = _("Disabled")
        $scope.allProjects = []
        $cross.listProjects $http, $window, $q, {}, (projects) ->
          for project in projects
            if project.name == adminProject
              $scope.adminProjectId = project.id
              continue
            item = {
              id: project.id
              name: project.name
            }
            if project.id == user.tenantId
              user.projectName = project.name
              initialUser = angular.copy(user)
              $scope.notify(initialUser)
              $scope.selectedProject = item
            $scope.allProjects.push item
          $scope.selectedProject = $scope.allProjects[0]
        $cross.listUserProjects $http, $window, $q, $scope.currentId,
        (data) ->
          if data.projects.length == 1
            $scope.singleProject = true
          if data.projects
            $scope.projectsUserBelongs = data.projects
            user.is_admin = false
            for proj in data.projects
              if proj.name == adminUser
                user.is_admin = true
            if user.is_admin
              $scope.ori_is_admin = true
              user.isAdmin = _('Yes')
            else
              $scope.ori_is_admin = false
              user.isAdmin = _('No')

        $scope.user_detail = user

    $scope.getUser()

    $scope.detailShow = () ->
      container = angular.element('.ui-view-container')
      $scope.detailHeight = $(window).height() - container.offset().top
      $scope.detailHeight -= 50
      $scope.detailWidth = container.width() * 0.70

    if $scope.currentId
      $scope.detail_show = "detail_show"
    else
      $scope.detail_show = "detail_hide"

    $scope.detailShow()
    $scope.user_detail_tabs = [
      {
        name: _('Overview'),
        url: 'admin.user.userId.overview',
        available: true
      }
    ]

    $scope.checkActive = () ->
      for tab in $scope.user_detail_tabs
        if tab.url == $state.current.name
          tab.active = 'active'
        else
          tab.active = ''

    $scope.panle_close = () ->
      $state.go 'admin.user'
      $scope.detail_show = false

    $scope.checkActive()

    resetTips = _("Confirm reset user's password to: ")
    originalPassword = $window.$CROSS.settings.originalPassword
    if !originalPassword
      originalPassword = 'cloud123'
      $log.warn "originalPassword need to set in config file!"

    $scope.resetPasswordTips = "#{resetTips}#{originalPassword} ?"
    $scope.resetPassword = () ->
      options = {
        userId: $scope.currentId
        password: originalPassword
      }
      $cross.updateUser $http, $window, options, (user) ->
        toastr.success _("Success to reset password!")
