'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:LoginCtrl
 # @description
 # # LoginCtrl
 # Controller of the Cross
###
angular.module("Cross.login", [])
  .controller "LoginCtrl", ($scope, $http, $location, $state,
  $window) ->

    # Initial field.
    $scope.loginPanel = true
    $scope.note =
      title: $window._ "Operation Management Platform"
      submit: $window._ "Login"
      username: $window._ "User Name"
      password: $window._ "Password"
      forget: $window._ "Forget Password ?"

    $scope.validator =
      note: $window._ "User name could not be empty!"
      isInvalid: false

    $scope.user =
      username: ""
      password: ""

    $scope.sendLoginRequest = ->
      if $scope.user.password == ""
        $scope.validator.note = $window._ "Password could not be empty!"
        $scope.validator.isInvalid = true
      else if $scope.user.username == ""
        $scope.validator.note = $window._ "User name could not be empty!"
        $scope.validator.isInvalid = true
      else
        $scope.validator.isInvalid = false
        authData =
            url: "#{$window.$CROSS.settings.serverURL}/login"
            method: 'POST'
            headers:
              'X-platform': $CROSS.settings.platform || 'Cross'
              'Content-Type': 'application/json'
            data:
              'username': $scope.user.username
              'password': $scope.user.password

        angular.element(".loading-container").show()
        angular.element("#login_submit").attr("disabled", true)
        $http authData
          .success (data, status, headers) ->
            angular.element(".loading-container").hide()
            angular.element("#login_submit").removeAttr("disabled")
            if $state.params.next
              location.hash = $state.params.next
            else
              location.hash = '#/admin/overview'
            location.reload()
          .error (err, status) ->
            angular.element(".loading-container").hide()
            angular.element("#login_submit").removeAttr("disabled")
            $scope.validator.isInvalid = true
            if status == 401
              message = "Username and password are not match!"
              if err.data and err.data.message
                if /^User is disabled.*/.test(error.data.message)
                  message = "User is disabled!"
              $scope.validator.note = $window._ message
            else if status == 402
              message = "Only admin users are allowed to login!"
              $scope.validator.note = $window._ message
            else if status < 500
              message = "Failed to submit user data!"
              $scope.validator.note = $window._ message
            else if status >= 500
              message = "Server error!"
              $scope.validator.note = $window._ message
