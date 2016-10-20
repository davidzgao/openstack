'use strict'

angular.module('Unicorn.reset', [])
  .controller 'ResetCtrl', ($scope, $http, $q, $rootScope,
  $state, $window, $stateParams, $timeout) ->

    $scope.note = {
      header: _("Reset Password")
      submit: _("Submit")
      forgetPassword: _("Forget Password")
      newPassword: _("New Password")
      newPasswordConf: _("Confirm Password")
      urlErrorTips: _("Please send a request to retrieve password again!")
      countDown: _(" seconds later, jump to the home page.")
    }

    title = $window.$UNICORN.settings.websiteTitle || 'ECONE'
    $rootScope.title = "#{title} - #{$scope.note.header}"

    $scope.registerMainHeight = $(window).height()
    angular.element(window).smartresize ->
      $scope.registerMainHeight = $(window).height()

    serverURL = $window.$UNICORN.settings.serverURL

    $scope.validateStatus = {}
    $scope.user = {}

    $scope.fieldDisabled = true
    $scope.urlCheckComplete = false
    $scope.urlCheckSuccess = false
    $scope.resetSuccess = false

    passwordCheck = (field, value) ->
      if field == 'password'
        password = $scope.user.password
        passwordConf = $scope.user.passwordConf
        if password
          if password.length >= 6
            $scope.validateStatus.password = 'valid'
            $scope.passwordStatus = 'correct'
          else
            $scope.validateStatus.password = 'invalid'
            $scope.passwordStatus = ''
          if passwordConf
            if passwordConf != password
              $scope.validateStatus.password = 'invalid'
              $scope.validateStatus.passwordConf = 'invalid'
              $scope.passwordStatus = 'error'
              $scope.passwordConfStatus = 'error'
              $scope.inputTips = _ ("The two passwords you typed do not match.")
            else
              $scope.validateStatus.password = 'valid'
              $scope.validateStatus.passwordConf = 'valid'
              $scope.passwordStatus = 'correct'
              $scope.passwordConfStatus = 'correct'
              $scope.inputTips = ''
      if field == 'passwordConf'
        password = $scope.user.password
        passwordConf = $scope.user.passwordConf
        if passwordConf and password
          if passwordConf != password
            $scope.validateStatus.password = 'invalid'
            $scope.validateStatus.passwordConf = 'invalid'
            $scope.passwordStatus = 'error'
            $scope.passwordConfStatus = 'error'
            $scope.inputTips = _ ("The two passwords you typed do not match.")
          else
            $scope.validateStatus.password = 'valid'
            $scope.validateStatus.passwordConf = 'valid'
            $scope.passwordStatus = 'correct'
            $scope.passwordConfStatus = 'correct'
            $scope.inputTips = ''

    $scope.inValidate = true
    $scope.$watch 'user', (newVal, oldVal) ->
      if newVal.password and newVal.password != oldVal.password
        passwordCheck('password', newVal.password)
      if newVal.passwordConf and newVal.passwordConf != oldVal.passwordConf
        passwordCheck('passwordConf', newVal.passwordConf)
    , true

    # Check the current URL is or not available
    $http.post "#{serverURL}/password/reset/check", $stateParams
    .success (status, res) ->
      $scope.urlCheckComplete = true
      $scope.fieldDisabled = false
      $scope.urlCheckSuccess = true
    .error (err) ->
      $scope.urlTips = _("The link has expired or is incomplete.")
      $scope.urlCheckComplete = true
      $scope.fieldDisabled = true
      $scope.urlCheckSuccess = false

    $scope.successCallback = () ->
      $scope.resetSuccess = true
      $scope.counter = 5
      $scope.onTimeout = () ->
        $scope.counter--
        mytimeout = $timeout($scope.onTimeout, 1000)
        if $scope.counter == 0
          $timeout.cancel(mytimeout)
          $state.go "login"
      mytimeout = $timeout($scope.onTimeout, 1000)

    $scope.resetSubmit = () ->
      passwordStatus = $scope.validateStatus.password
      passwordConfStatus = $scope.validateStatus.passwordConf
      if !passwordStatus
        $scope.inputTips = (_("Please input ") + _ "password")
      if !passwordConfStatus
        $scope.inputTips = (_("Please input ") + _ "password")

      if passwordStatus == 'valid' and passwordConfStatus == 'valid'
        data = {
          userId: $stateParams.userId
          password: $scope.user.password
          params: $stateParams
        }
        $scope.fieldDisabled = true
        $scope.showLoading = true
        $http.post "#{serverURL}/password/reset", data
          .success (status, res) ->
            $scope.showLoading = false
            $scope.successCallback()
          .error (err) ->
            toastr.error _("Failed to reset the password! Try again later!")

    $scope.goBack = () ->
      $state.go 'login'
