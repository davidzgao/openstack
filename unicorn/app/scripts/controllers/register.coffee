'use strict'

###*
 # @ngdoc function
 # @name Unicorn.controller:RegisterCtrl
 # @description
 # Controller of the Unicorn
###
angular.module('Unicorn.register', ['ngCookies'])
  .controller 'RegisterCtrl', ($scope, $modal, $http, $q, $rootScope,
  $state, $window, $timeout) ->

    $scope.note = {
      header: _("Register New User")
      username: _("User Name")
      email: _("Email")
      password: _("Password")
      passwordConf: _("Confirm Password")
      submit: _("Register")
      congratulation: _("Congratulation, Register Success!")
      successTips: _("After approve by administrator, you will receive email notification.")
      countDown: _(" seconds later, jump to the home page.")
    }
    $scope.fieldTipsMap = {
      username: _ "Input a username, length between 4 to 20."
      email: _ "Please input an effective email."
      password: _ "Input a password, length between 6 to 20."
      passwordConf: _ "Input your password again!"
    }

    title = $window.$UNICORN.settings.websiteTitle || 'ECONE'
    $rootScope.title = "#{title} - #{$scope.note.submit}"

    $scope.registerMainHeight = $(window).height()
    angular.element(window).smartresize ->
      $scope.registerMainHeight = $(window).height()

    $scope.user = {}
    $scope.validateStatus = {}
    $scope.filedsList = ['username', 'email', 'password', 'passwordConf']

    serverURL = $window.$UNICORN.settings.serverURL
    usernameCheck = (username) ->
      if !username
        $scope.validateStatus.username = undefined
        $scope.usernameStatus = ''
        return
      reg = /^[a-zA-Z0-9_]+$/
      if !reg.test(username)
        $scope.validateStatus.username = 'invalid'
        $scope.usernameStatus = 'error'
        $scope.inputTips = _ "Username consist with latter, number and _ only"
        return
      if username.length >= 4
        $http.get("#{serverURL}/register?name=#{username}")
          .success (data) ->
            if data.has == 0
              $scope.validateStatus.username = 'valid'
              $scope.usernameStatus = 'correct'
              $scope.inputTips = ''
            else
              $scope.validateStatus.username = 'invalid'
              $scope.usernameStatus = 'error'
              $scope.inputTips = _ "User name has been registered!"
      else
        $scope.validateStatus.username = 'invalid'
        $scope.usernameStatus = 'error'
        $scope.inputTips = $scope.fieldTipsMap.username

    emailCheck = (email) ->
      if !email
        $scope.validateStatus.email = undefined
        $scope.emailStatus = ''
        return
      emailRegExp = /\S+@\S+\.\w+/
      if emailRegExp.test(email)
        $http.get("#{serverURL}/register?email=#{email}")
          .success (data) ->
            if data.has == 0
              $scope.validateStatus.email = 'valid'
              $scope.emailStatus = 'correct'
              $scope.inputTips = ''
            else
              $scope.validateStatus.email = 'invalid'
              $scope.emailStatus = 'error'
              $scope.inputTips = _ "Email address has been registered!"
      else
        $scope.validateStatus.email = 'invalid'
        $scope.emailStatus = 'error'
        $scope.inputTips = $scope.fieldTipsMap.email

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

    $scope.fieldBlur = (field) ->
      if field == 'username'
        usernameCheck $scope.user.username
      if field == 'email'
        emailCheck $scope.user.email

    $scope.successCallback = () ->
      $scope.registerSuccess = true
      $scope.counter = 5
      $scope.onTimeout = () ->
        $scope.counter--
        mytimeout = $timeout($scope.onTimeout, 1000)
        if $scope.counter == 0
          $timeout.cancel(mytimeout)
          $state.go "login"
      mytimeout = $timeout($scope.onTimeout, 1000)

    $scope.goBack = () ->
      $state.go 'login'

    $scope.registerSubmit = () ->
      validCounts = 0
      for filed in $scope.filedsList
        if !$scope.validateStatus[filed]\
        or $scope.validateStatus[filed] == 'invalid'\
        or $scope.validateStatus[filed] == ''
          if !$scope.user[filed]
            $scope.validateStatus[filed] = 'invalid'
            $scope["#{filed}Status"] = 'error'
            filedVer = _ filed
            $scope.inputTips = _("Please input ") + filedVer
            break
          else
            if filed == 'username'
              usernameCheck($scope.user.username)
            if filed == 'email'
              emailCheck($scope.user.email)
        else
          validCounts += 1
          continue
      if validCounts == 4
        registerData = {
          name: $scope.user.username
          password: $scope.user.password
          email: $scope.user.email
        }
        $scope.showLoading = true
        $scope.fieldDisabled = true
        $http.post("#{serverURL}/register", registerData)
          .success (data) ->
            $scope.showLoading = false
            $scope.successCallback()
          .error (err) ->
            $scope.fieldDisabled = false
      else
        return
