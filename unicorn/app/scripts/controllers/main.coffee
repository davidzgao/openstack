'use strict'

###*
 # @ngdoc function
 # @name Unicorn.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Unicorn
###
angular.module('Unicorn.main', ['ngCookies'])
  .controller 'MainCtrl', ($scope, $modal, $http, $q, $rootScope, $gossip,
                           $state, $window, $timeout, $cookies, $cookieStore) ->
    $scope.$on "$destroy", ->
      $gossip.closeConnection()

    # initial current dashboard.
    defaultView = $UNICORN.settings.defaultView
    view = $UNICORN.view || defaultView
    dashboards = $UNICORN.dashboards || {}
    $rootScope.$dashboards = dashboards[view] || []
    $rootScope.$view = view
    $scope.guide = _ "guide"

    $scope.logoHyperLink = $UNICORN.settings.hyperLink or\
                           "http://www.hihuron.com"

    MOUSE_DELAY = 70

    serverUrl = $UNICORN.settings.serverURL
    $scope.note =
      logout: _("logout")
      more: _("more")

    if $UNICORN.person
      $scope.user =
        name: $UNICORN.person.user.name
      $scope.currentProject = $UNICORN.person.project.name

    msgRec = (message) ->
      # Handle message tips.

    $gossip.connect msgRec

    extractRegionInfo = (region) ->
      extra = region.extra or {}
      $UNICORN.settings.enable_lbaas = extra.enable_lbaas or false
      $UNICORN.settings.hypervisor_type = extra.hypervisor_type or $UNICORN.settings.defaultHypervisorType
      for service in region.endpoints
        if service.type == "network"
          useNeutron = true

      if useNeutron == true
        $UNICORN.settings.use_neutron = true
      else
        $UNICORN.settings.use_neutron = false

    $scope.logout = ->
      $http.get "#{serverUrl}/logout"
        .success ->
          params =
            inherit: false
            reload: true
          $state.go 'login', null, params
          $gossip.closeConnection()
          $window.$UNICORN.person = undefined
          location.hash = "#/login"
          location.reload()
        .error (err) ->
          toastr.error _("Failed to logout")

    # handle actions about project.
    $scope.showSelect = false
    defaultView = $UNICORN.settings.defaultView
    view = $UNICORN.view || defaultView
    dashboards = $UNICORN.dashboards || {}
    $rootScope.$dashboards = dashboards[view] || []
    $rootScope.$view = view

    showProject = ->
      $scope.dash =
        search: ""

      # get project from cookies.
      RECENT_USE_NUMBER = 4
      STORE_KEY_HASH = "unicornRecentProjects"
      recProjects = $cookieStore.get(STORE_KEY_HASH)
      recProjects = recProjects || []
      if typeof recProjects == 'string'
        recProjects = JSON.parse recProjects
      $scope.allowedRec = []

      $http.get "#{serverUrl}/regions"
        .success (regions) ->
          $scope.otherRegions = []
          if not regions
            return
          if regions.length > 1
            $scope.multiRegion = 'show'
          for region in regions
            if region.active
              $scope.currentRegion = region
              extractRegionInfo(region)
            else
              $scope.otherRegions.push region

      # get project list.
      $http.get "#{serverUrl}/userProjects"
        .success (projects) ->
          person = $UNICORN.person
          view = $rootScope.$view
          hiddenProjects = $UNICORN.settings.hiddenProjects or []
          allowedRecPros = []
          for pro in projects
            break if allowedRecPros.length > RECENT_USE_NUMBER
            for project in projects
              if hiddenProjects and project.name in hiddenProjects
                continue
              if pro.id == project.id
                pro.isActive = false
                if person && person.project.id == pro.id
                  pro.isActive = true
                allowedRecPros.push pro
                break
          $scope.allowedRec = allowedRecPros
          # store active project.
          $cookieStore.put(STORE_KEY_HASH, JSON.stringify($scope.allowedRec))

          allowProjects = []
          for project in projects
            if hiddenProjects and project.name in hiddenProjects
              continue
            item =
              id: project.id
              name: project.name
            if person && person.project.id == project.id
              item.isActive = true
            if $scope.allowedRec.length < RECENT_USE_NUMBER
              isIn = false
              for pro in $scope.allowedRec
                if pro.id == project.id
                  isIn = true
                  break
              $scope.allowedRec.push(item) if not isIn
            item.isShow = true
            allowProjects.push item
          $scope.dash.projects = allowProjects
          if projects.length > RECENT_USE_NUMBER
            $scope.enoughProjects = true

          $scope.dash.recProjects = $scope.allowedRec
        .error (err) ->
          toastr.error _("Failed to get projects")

      $scope.searchProjects = ->
        val = $scope.dash.search
        if typeof val == "string"
          val = val.toLowerCase()
        else
          val = ""

        for pro in $scope.dash.projects
          if val == ""
            pro.isShow = true
            continue
          lower = pro.name.toLowerCase()
          if lower.indexOf(val) == -1
            pro.isShow = false
          else
            pro.isShow = true
        return

      $scope.selectedProject = (projectID, projectName) ->
        person = $UNICORN.person
        if person && person.project.id == projectID
          return

        $window.$UNICORN.currentProject = projectID
        $scope.showLoading = true
        $http.get "#{serverUrl}/switch/#{projectID}"
          .success (person) ->
            $scope.showLoading = false
            $UNICORN.person = person
            params =
              reload: true
              inherit: false
              notify: true
            # store recent project info.
            allowedRec = [{
              id: projectID
              name: projectName
            }]
            counter = 0
            for pro in $scope.allowedRec
              break if counter >= RECENT_USE_NUMBER - 1
              if projectID == pro.id
                continue
              item =
                id: pro.id
                name: pro.name
              allowedRec.push item
              counter += 1
            $cookieStore.put(STORE_KEY_HASH, JSON.stringify(allowedRec))
            $gossip.closeConnection()
            toastr.clear()
            $state.go "dashboard.overview", null, params
          .error (err)->
            toastr.error _("Failed to switch project")
            $scope.showLoading = false

    $scope.switchRegion = (regionName) ->
      $scope.showLoading = true
      params =
        reload: true
        inherit: false
        notify: true
      $http.post "#{serverUrl}/regions/switch", {region: regionName}
        .success (regions) ->
          $scope.otherRegions = []
          for region in regions
            if region.active
              $scope.currentRegion = region
              extractRegionInfo region
            else
              $scope.otherRegions.push region
          location.hash = "#/dashboard/overview"
          location.reload()
        .error (err) ->
          $scope.showLoading = false
          toastr.error _ (["Failed to switch to %s region", regionName])

    # load project list.
    showProject()
    $scope.selectDashboard = ->
      if $scope.showSelect
        $scope.showSelect = false
        $scope.hideDash = true
        $scope.dash.show = false
        $scope.hideProjectList = true
        $scope.note.more = _("more")
      else
        $scope.hideDash = false
        $scope.showSelect = true

    delayId = null
    $scope.dashboardBlur = ->
      $scope.hideDash = true
      if delayId
        clearTimeout delayId
      delayId = $timeout ->
        if $scope.hideDash
          delayId = null
          $scope.showSelect = false
          $scope.hideDash = true
          $scope.dash.show = false
          $scope.hideProjectList = true
          $scope.note.more = _("more")
          if !$scope.$$phase
            $scope.$apply()
      , MOUSE_DELAY

    $scope.multiRegion = 'hidden'
    $scope.showRegions = false
    $scope.selectRegion = ->
      if $scope.otherRegions.length > 0
        $scope.showRegions = true
      else
        $scope.showRegions = false

    regionDelay = undefined
    $scope.regionBlur = ->
      if regionDelay
        clearTimeout regionDelay
      regionDelay = $timeout ->
        $scope.showRegions = false
      , MOUSE_DELAY

    $scope.inputFocus = ->
      if delayId
        $scope.hideDash = false
        clearTimeout delayId

    $scope.inputBlur = ->
      $scope.hideDash = true
      if delayId
        clearTimeout delayId
      delayId = $timeout ->
        if $scope.hideDash
          delayId = null
          $scope.dash.show = false
          $scope.showSelect = false
          $scope.hideProjectList = true
          $scope.note.more = _("more")
      , MOUSE_DELAY * 2

    $scope.hideProjectList = true
    $scope.dashMouseEnter = (slug) ->
      if not $scope.hideProjectList
        $scope.dash.show = false
        $scope.hideProjectList = true
        $scope.note.more = _("more")
      else
        $scope.dash.show = true
        $scope.hideProjectList = false
        $scope.note.more = _("Hidden")

    $scope.userSetting = {
      show: false
      info: _("User Setting")
    }

    $scope.userSettingBlur = () ->
      $scope.userSetting.show = false

    $scope.userSetting.list = () ->
      if !$scope.userSetting.show
        $scope.userSetting.show = true

    $scope.userId = ''
    $scope.showUserInfo = () ->
      reqParams =
        url: "#{$UNICORN.settings.serverURL}/auth"
        method: 'GET'
      $http reqParams
        .success (data, status, headers) ->
          $scope.userId = data.user.id
          $state.go 'dashboard.userInfo', {userId: $scope.userId}
  .controller 'userInfo', ($scope, $http, $state, $stateParams, $window) ->
    $scope.userInfo = _("User Info")
    $scope.action = {
      save: _("Save")
      edit: _("Edit")
      cancel: _("Cancel")
      modifyPass: _('Change Password')
    }
    $scope.infoLabels = {
      username: _("User Name")
      email: _("Email")
      password: _("Password")
    }
    $scope.free = _("None")

    $scope.user = {}
    $scope.userId = $stateParams.userId

    $scope.tmp = {
      username: ''
      email: ''
    }
    $scope.validateInfo = {
      nameInva: false
      emailInva: false
      nameTips: ''
      emailTips: ''
      invaClass: ''
    }
    $scope.changePasswordButton = '<a class="link" ui-sref="dashboard.userInfo.changePass({userId:userId})">{{action.modifyPass}}</a>'

    serverURL = $window.$UNICORN.settings.serverURL
    reqParams =
      url: "#{serverURL}/users/#{$scope.userId}"
      method: 'GET'
    $http reqParams
      .success (user, status, headers) ->
        $scope.user = user
        $scope.tmp.username = user.name
        $scope.tmp.email = user.email
        if user.email == null or user.email == 'null' or user.email == ''
          $scope.user.email = ''
          $scope.user.emailDisplay = "<#{$scope.free}>"
        else
          $scope.user.emailDisplay = user.email
      .error (error, status) ->
        toastr.error _("Failed to get user detail!")

    $scope.inEdit = 'fixed'
    $scope.editing = false

    $scope.edit = () ->
      if $scope.inEdit == 'fixed'
        $scope.inEdit = 'editing'
        $scope.editing = true
      else
        $scope.inEdit = 'fixed'
        $scope.editing = false
        return
    $scope.cancel = () ->
      $scope.validateInfo = {
        nameInva: false
        emailInva: false
        nameTips: ''
        emailTips: ''
        invaClass: ''
      }
      $scope.tmp = {
        username: $scope.user.name
        email: $scope.user.email
      }
      $scope.inEdit = 'fixed'
      $scope.editing = false

    $scope.checkName = () ->
      name = $scope.tmp.username
      if name
        if name.length < 4 or name.length > 20
          $scope.validateInfo.invaClass = 'ng-invalid'
          $scope.validateInfo.nameInva = true
          $scope.validateInfo.nameTips = _("Length must between 4 and 20.")
        else
          $scope.validateInfo.invaClass = ''
          $scope.validateInfo.nameInva = false
      else
          $scope.validateInfo.nameInva = true
          $scope.validateInfo.nameTips = _("Cannot be empty.")


    $scope.checkEmail = () ->
      email = $scope.tmp.email
      emailRe = /\S+@\S+\.\S+/
      if email
        if not emailRe.test(email)
          $scope.validateInfo.emailInvaClass = 'ng-invalid'
          $scope.validateInfo.emailInva = true
          $scope.validateInfo.emailTips = _("Email format error.")
        else
          $scope.validateInfo.emailInva = false
          $scope.validateInfo.emailInvaClass = ''
      else
        $scope.validateInfo.emailInva = true
        $scope.validateInfo.emailTips = _("Cannot be empty.")

    $scope.save = () ->
      if $scope.validateInfo.nameInva or $scope.validateInfo.emailInva
        $scope.checkName()
        $scope.checkEmail()
      else
        $scope.inEdit = 'fixed'
        $scope.editing = false

        if $scope.user.username == $scope.tmp.username\
        and $scope.user.email == $scope.tmp.email
          return
        userParam = "#{serverURL}/users/#{$scope.userId}"
        options = {
          name: $scope.tmp.username
          email: $scope.tmp.email
          tenantId: $scope.user.projectId
          default_project_id: $scope.user.projectId
        }
        $http.put userParam, options
          .success (data, status, headers) ->
            if !data
              $scope.user.name = options.name
              $scope.user.email = options.email
              return
            $scope.user = data.user
            $scope.tmp.username = data.user.name
            $scope.tmp.email = data.user.email
            if $scope.user.email == null or $scope.user.email == 'null' or $scope.user.email == ''
              $scope.user.email = ''
              $scope.user.emailDisplay = "<#{$scope.free}>"
            else
              $scope.user.emailDisplay = $scope.user.email
            toastr.success _("Sussfully update user info.")
          .error (data, status, headers) ->
            $scope.tmp.username  = $scope.user.name
            $scope.tmp.email     = $scope.user.email
            toastr.error _("Failed to update user info.")
  .controller 'ModifyPassword', ($scope, $http, $state,
  $stateParams, $window) ->
    (new ModifyPasswordModal()).initial($scope,
      {
        $state: $state,
        $http: $http,
        $window: $window,
        userId: $stateParams.userId
      })
    $scope.note.modal.save = _("Update")

class ModifyPasswordModal extends $unicorn.Modal
  title: _ "Modify Password"
  slug: "modify_password"

  fields: ->
    [{
      slug: "current_password"
      label: _ "Current Password"
      tag: "input"
      type: "password"
      restrications:
        required: true
    }
    {
      slug: "new_password"
      label: _ "New Password"
      tag: "input"
      type: "password"
      restrictions:
        required: true
        len: [6, 20]
        func: ($scope, val) ->
          current_field = $scope.modal.fields[1]
          len = current_field.restrictions.len
          if val.length < len[0] or val.length > len[1]
            tipsHead = _("Length must between ")
            tipsValue = "#{len[0]} ~ #{len[1]}"
            tipsBot = _ " among."
            lengthTips = "#{tipsHead}#{tipsValue}#{tipsBot}"
            $scope.tips['new_password'] = lengthTips
          else
            if $scope.form.confirm_password
              if val != $scope.form.confirm_password
                diffTip = _ "The two passwords you typed do not match."
                $scope.tips['confirm_password'] = diffTip
                $scope.tips['new_password'] = diffTip
              else
                $scope.tips['confirm_password'] = ''
                $scope.tips['new_password'] = ''
    }
    {
      slug: "confirm_password"
      label: _ "Confirm New Password"
      tag: "input"
      type: "password"
      restrictions:
        required: true
        len: [6, 20]
        func: ($scope, val) ->
          current_field = $scope.modal.fields[2]
          len = current_field.restrictions.len
          if val.length < len[0] or val.length > len[1]
            tipsHead = _("Length must between ")
            tipsValue = "#{len[0]} ~ #{len[1]}"
            tipsBot = _ " among."
            lengthTips = "#{tipsHead}#{tipsValue}#{tipsBot}"
            $scope.tips['confirm_password'] = lengthTips
          else
            if $scope.form.new_password
              if val != $scope.form.new_password
                diffTip = _ "The two passwords you typed do not match."
                $scope.tips['confirm_password'] = diffTip
                $scope.tips['new_password'] = diffTip
              else
                $scope.tips['confirm_password'] = ''
                $scope.tips['new_password'] = ''
    }
    ]

  handle: ($scope, options) ->
    serverURL = options.$window.$UNICORN.settings.serverURL
    $scope.logout = ->
      logoutParams =
        url: "#{serverURL}/logout"
        method: 'GET'
      options.$http logoutParams
        .success (data, status) ->
          $UNICORN.project = null
          options.$state.go 'login'

    userId = options.userId
    params = {
      user_id: userId
      old_password: $scope.form.current_password
      new_password: $scope.form.new_password
    }
    userURL = "#{serverURL}/users/#{userId}"
    options.$http.put userURL, params
      .success (data, status, header) ->
        toastr.success _("Success update password")
        $scope.logout()
      .error (data, status, header) ->
        options.$state.go "^"
        if data == 'Current password error'
          toastr.error _("Current password error!")
        else
          toastr.error _("Modify password failed!")

  close: ($scope, options) ->
    options.$state.go "^"
