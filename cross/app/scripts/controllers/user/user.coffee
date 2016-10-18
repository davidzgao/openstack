'use strict'

angular.module('Cross.user', [])
  .controller 'UserCtrl', ($scope, $http, $rootScope, $state, $window,
  $cookieStore, $timeout, $gossip) ->
    $scope.username = ""
    $scope.userId = ""
    $scope.setting = _ 'User Setting'
    $scope.changeView = _ 'Change View'

    $scope.showInfo = false
    $scope.userInfo = () ->
      if $scope.showInfo
        $scope.showInfo = false
      else
        $scope.showInfo = true

    DELAY_TIME = 70
    delayId = null
    $scope.userBlur = ->
      if delayId
        clearTimeout delayId
      delayId = $timeout ->
        $scope.showInfo = false
      , DELAY_TIME

    $scope.userSetting = () ->
      $scope.showInfo = false
      $state.go 'admin.userInfo', { userId: $scope.userId }

    reqParams =
      url: "#{$CROSS.settings.serverURL}/auth"
      method: 'GET'
    $http reqParams
      .success (data, status, headers) ->
        $scope.username = data.user.name
        $scope.userId = data.user.id
        # NOTE(ZhengYue): Save the current user's id in cookie.
        $cookieStore.put('currentUserId', $scope.userId)
        userParams =
          url: "#{$window.$CROSS.settings.serverURL}/users/#{$scope.userId}"
          method: 'GET'
        $http userParams
          .success (data, status, headers) ->
            $scope.user = data
          .error (error, status) ->
            toastr.options.closebutton = true
            toastr.error _("Field to get current user info.")

    $scope.logout = ->
      logoutParams =
        url: "#{$window.$CROSS.settings.serverURL}/logout"
        method: 'GET'
      $http logoutParams
        .success (data, status) ->
          $CROSS.person = null
          $CROSS.view = null
          $CROSS.currentProject = null
          $cookieStore.remove 'currentUserId'
          $gossip.closeConnection()
          location.hash = "#/login"
          location.reload()
        .error (error, status) ->
          toastr.options.closebutton = true
          toastr.error _("Field to logout, try again later!")

  .controller 'userInfo', ($scope, $http, $state, $stateParams, $window) ->
    $scope.tabs = [{
      title: _('User Info')
      template: 'user.info.html'
      enable: true
    }]

    $scope.action = {
      save: _("Save")
      edit: _("Edit")
      cancel: _("Cancel")
    }

    $scope.infoLabels = {
      username: _ 'User Name'
      email: _ 'E-Mail'
      password: _ 'Password'
    }
    $scope.free = _ "None"

    $scope.currentTab = 'user.info.html'
    $scope.onClickTab = (tab) ->
      $scope.currentTab = tab.template
    $scope.isActiveTab = (tabUrl) ->
      return tabUrl == $scope.currentTab

    $scope.user = {}
    $scope.userId = $stateParams.userId
    $scope.username = ''
    $scope.email = ''
    $scope.emailDisplay = ''
    $scope.modifyPass = _('Change Password')
    $scope.changePasswordButton = '<a class="link" ui-sref="admin.userInfo.changePass({userId:userId})">{{modifyPass}}</a>'

    $scope.user = {}
    serverURL = $window.$CROSS.settings.serverURL
    reqParams =
      url: "#{serverURL}/users/#{$scope.userId}"
      method: 'GET'
    $http reqParams
      .success (user, status, headers) ->
        $scope.user.username = user.name
        $scope.userId = user.id
        $scope.usernameOri = user.name
        $scope.user.projectId = user.tenantId
        if user.email == null or user.email == 'null' or user.email == ''
          $scope.user.email = ''
          $scope.user.emailDisplay = "<#{$scope.free}>"
        else
          $scope.user.email = user.email
          $scope.user.emailDisplay = user.email

        $scope.emailOri = $scope.user.email
        $scope.emailDisplayOri = $scope.user.emailDisplay
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
      $scope.nameInValidate = false
      $scope.emailInValidate = false
      $scope.nameTips = ''
      $scope.emailTips = ''
      $scope.user.username = $scope.usernameOri
      $scope.user.email = $scope.emailOri
      $scope.user.emailDisplay = $scope.emailDisplayOri
      $scope.inEdit = 'fixed'
      $scope.editing = false

    $scope.checkName = () ->
      name = $scope.user.username
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
      email = $scope.user.email
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

    $scope.save = () ->
      if $scope.nameInValidate or $scope.emailInValidate
        $scope.checkName()
        $scope.checkEmail()
      else
        $scope.inEdit = 'fixed'
        $scope.editing = false

        options = {
          userId: $scope.userId
          name: $scope.user.username
          email: $scope.user.email
          tenantId: $scope.user.projectId
        }
        if $scope.user.username == $scope.usernameOri\
        and $scope.user.email == $scope.emailOri
          return
        $cross.updateUser $http, $window, options, (data, status) ->
          if status != 200 and status != '200'
            toastr.error _("Failed to update user info!")
            return
          user = data.user
          $scope.user.username = user.name
          $scope.userId = user.id
          $scope.usernameOri = user.name
          $scope.user.projectId = user.tenantId
          if user.email == null or user.email == 'null' or user.email == ''
            $scope.user.email = ''
            $scope.user.emailDisplay = "<#{$scope.free}>"
          else
            $scope.user.email = user.email
            $scope.user.emailDisplay = user.email

          $scope.emailOri = $scope.user.email
          $scope.emailDisplayOri = $scope.user.emailDisplay
          toastr.success _("Success update user!")

    $scope.changeName = () ->
      userId = $scope.userId
      params = {
        name: $scope.username
      }
      serverURL = $window.$CROSS.settings.serverURL
      userURL = "#{serverURL}/users/#{userId}"
      $http.put userURL, params
        .success (data, status, header) ->
          # TODO(ZhengYue): Add success tips.
          console.log data
        .error (data, status, header) ->
          # TODO(ZhengYue): Add falied tips.

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

class ModifyPasswordModal extends $cross.Modal
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
    $scope.logout = ->
      logoutParams =
        url: "#{options.$window.$CROSS.settings.serverURL}/logout"
        method: 'GET'
      options.$http logoutParams
        .success (data, status) ->
          $CROSS.project = null
          options.$state.go 'login.login', {}, {reload: true}

    userId = options.userId
    params = {
      user_id: userId
      old_password: $scope.form.current_password
      new_password: $scope.form.new_password
    }
    serverURL = options.$window.$CROSS.settings.serverURL
    userURL = "#{serverURL}/users/#{userId}"
    options.$http.put userURL, params
      .success (data, status, header) ->
        toastr.success _("Success update password, Please login again.")
        $scope.logout()
      .error (data, status, header) ->
        options.$state.go "login.login"
        if data == 'Current password error'
          toastr.error _("Current password error!")
        else
          toastr.error _("Modify password failed!")

  close: ($scope, options) ->
    options.$state.go "login.login"
