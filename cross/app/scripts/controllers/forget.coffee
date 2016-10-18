'use strict'

angular.module('Cross.forget', [])
  .controller 'ForgetPasswordCtrl', ($scope, $http, $q, $rootScope,
  $state, $window) ->

    $scope.note = {
      header: _("Retrieve Password")
      email: _("Register Email")
      submit: _("Submit")
      congratulation: _("Succeed to send email!")
      return: _("Return To Login")
    }

    $scope.user = {}
    $scope.validateStatus = {}
    $scope.validator = {}

    emailCheck = (email) ->
      if !email
        $scope.validator.isInvalid = true
        $scope.validator.note = _ "Please input an effective email."
        $scope.emailStatus = ''
        return
      emailRegExp = /\S+@\S+\.\S+/
      if emailRegExp.test(email)
        $scope.validator.isInvalid = false
        $scope.emailStatus = 'correct'
        $scope.validator.note = ''
      else
        $scope.validator.isInvalid = true
        $scope.emailStatus = 'error'
        $scope.validator.note = _ "Please input an effective email."

    serverURL = $window.$CROSS.settings.serverURL

    $scope.fieldBlur = (field) ->
      emailCheck $scope.user.email

    $scope.retireveSubmit = () ->
      email = $scope.user.email
      emailCheck(email)
      if $scope.validator.isInvalid
        $scope.inputTips = _ "Please input an effective email."
      else
        angular.element(".loading-container").show()
        angular.element("#login_submit").attr("disabled", true)
        data = {email: $scope.user.email}
        $http.post "#{serverURL}/password/retrieve", data
        .success (data) ->
          angular.element(".loading-container").hide()
          angular.element("#login_submit").attr("disabled", false)
          $scope.registerSuccess = true
          $state.go 'login.retirevesuccess', {action: 'retireve'}
        .error (err) ->
          angular.element(".loading-container").hide()
          angular.element("#login_submit").attr("disabled", false)
          $scope.validator.isInvalid = true
          $scope.validator.note = _ err.error

  .controller 'passwordSuccessCtrl', ($scope, $http, $q, $rootScope,
  $state, $window, $stateParams, $timeout) ->
    $scope.$parent.loginPanel = false
    $scope.actionStatus = 'action-success'
    if $stateParams.action == 'retireve'
      $scope.note = {
        title: _("The password reset mail has been sent.")
        tips: _("We have sent you an email containing a link that will
          allow you to reset your password for the next 24 hours.")
        tip: _("Please check your spam folder if the email does not
          appear within a few minutes.")
      }
    if $stateParams.action == 'reset'
      $scope.note = {
        title: _("Succeed to reset password!")
        tips: _(" seconds later, jump to the home page.")
      }
      $scope.counter = 5
      $scope.onTimeout = () ->
        $scope.counter--
        mytimeout = $timeout($scope.onTimeout, 1000)
        if $scope.counter == 0
          $timeout.cancel(mytimeout)
          $state.go 'login.login'
      mytimeout = $timeout($scope.onTimeout, 1000)

    if $stateParams.action == 'expired'
      $scope.actionStatus = 'action-failed'
      $scope.note = {
        title: _("The link has expired or is incomplete.")
        tips: _("Please send a request to retrieve password again!")
      }

    $scope.goToLogin = () ->
      $scope.$parent.loginPanel = true
      $state.go 'login.login'
    $scope.note.login = _("Return To Login")
    $scope.note.forget = _("Send mail again!")

  .controller 'passwordResetCtrl', ($scope, $http, $q, $rootScope,
  $state, $window, $stateParams) ->
    $scope.note = {
      title: _("Reset password")
      return: _("Return To Login")
      submit: _("Submit")
      password: _("New Password")
      passwordConf: _("Confirm Password")
    }
    serverURL = $window.$CROSS.settings.serverURL
    # Check the current URL is or not available
    angular.element("#login_submit").attr("disabled", true)
    $http.post "#{serverURL}/password/reset/check", $stateParams
    .success (status, res) ->
      angular.element("#login_submit").attr("disabled", false)
    .error (err) ->
      $state.go "login.retirevesuccess", {action: 'expired'}

    $scope.validateStatus = {}
    $scope.user = {}
    $scope.validator = {}

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
            $scope.validator.isInvalid = false
            $scope.passwordStatus = ''
          if passwordConf
            if passwordConf != password
              $scope.validateStatus.password = 'invalid'
              $scope.validateStatus.passwordConf = 'invalid'
              $scope.validator.isInvalid = true
              $scope.passwordStatus = 'error'
              $scope.passwordConfStatus = 'error'
              $scope.inputTips = _ ("The two passwords you typed do not match.")
            else
              $scope.validateStatus.password = 'valid'
              $scope.validateStatus.passwordConf = 'valid'
              $scope.passwordStatus = 'correct'
              $scope.passwordConfStatus = 'correct'
              $scope.validator.isInvalid = false
              $scope.inputTips = ''
      if field == 'passwordConf'
        password = $scope.user.password
        passwordConf = $scope.user.passwordConf
        if passwordConf and password
          if passwordConf != password
            $scope.validateStatus.password = 'invalid'
            $scope.validateStatus.passwordConf = 'invalid'
            $scope.validator.isInvalid = true
            $scope.passwordStatus = 'error'
            $scope.passwordConfStatus = 'error'
            $scope.inputTips = _ ("The two passwords you typed do not match.")
          else
            $scope.validateStatus.password = 'valid'
            $scope.validateStatus.passwordConf = 'valid'
            $scope.validator.isInvalid = false
            $scope.passwordStatus = 'correct'
            $scope.passwordConfStatus = 'correct'
            $scope.inputTips = ''

    $scope.$watch 'user', (newVal, oldVal) ->
      if newVal.password and newVal.password != oldVal.password
        passwordCheck('password', newVal.password)
      if newVal.passwordConf and newVal.passwordConf != oldVal.passwordConf
        passwordCheck('passwordConf', newVal.passwordConf)
    , true

    $scope.resetSubmit = () ->
      passwordStatus = $scope.validateStatus.password
      passwordConfStatus = $scope.validateStatus.passwordConf
      if !passwordConfStatus
        $scope.inputTips = (_("Please input ") + _ "password")
        $scope.validator.isInvalid = true
      if !passwordStatus
        $scope.inputTips = (_("Please input ") + _ "password")
        $scope.validator.isInvalid = true

      if passwordStatus == 'valid' and passwordConfStatus == 'valid'
        data = {
          userId: $stateParams.userId
          password: $scope.user.password
          params: $stateParams
        }
        angular.element(".loading-container").show()
        angular.element("#login_submit").attr("disabled", true)
        $http.post "#{serverURL}/password/reset", data
          .success (status, res) ->
            angular.element(".loading-container").hide()
            angular.element("#login_submit").attr("disabled", false)
            $state.go 'login.retirevesuccess', {action: 'reset'}
          .error (err) ->
            angular.element(".loading-container").hide()
            angular.element("#login_submit").attr("disabled", false)
            toastr.error _("Failed to reset the password! Try again later!")
