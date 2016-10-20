'use strict'

###*
 # @ngdoc function
 # @name Unicorn.controller:LoginCtrl
 # @description
 # # MainCtrl
 # Controller of the Unicorn
###
angular.module('Unicorn.login', ['ngCookies'])
  .controller 'LoginCtrl', ($scope, $http, $rootScope, $location,
                           $state, $window, $desktopLogin) ->
    $scope.note =
      platform: _("Operations Management Platform")
      login: _("Login")
      forgetPass: _("Forget pass")
      register: _("Register")
      adminLogin: _("Admin login")
    title = $window.$UNICORN.settings.websiteTitle || 'ECONE'
    $rootScope.title = "#{title} - #{$scope.note.login}"

    $scope.auth =
      username:
        text: ""
        invalid: ""
      password:
        text: ""
        password: ""
    $scope.validator =
      note: ""

    $scope.login = ->
      if $scope.auth.password.text == ""
        $scope.validator.note = _("Password could not be empty!")
        $scope.auth.password.invalid = 'invalid'
      else if $scope.auth.username.text == ""
        $scope.validator.note = _("User name could not be empty!")
        $scope.auth.username.invalid = 'invalid'
      else
        $scope.auth.password.invalid = false
        $scope.auth.username.invalid = false
        authData = {
          url: "#{$UNICORN.settings.serverURL}/login"
          method: 'POST'
          headers:
            'X-platform': $UNICORN.settings.platform || 'Unicorn'
            'Content-Type': 'application/json'
          dataType: 'json'
          data:
            'username': $scope.auth.username.text
            'password': $scope.auth.password.text
            'normal': true
          responseType: 'application/json'
          cache: false
        }

        $scope.showLoading = true
        $scope.disableLogin = true
        errorHandler = (error, status) ->
          $scope.auth.password.invalid = true
          $scope.auth.username.invalid = true
          $scope.showLoading = false
          $scope.disableLogin = false
          if error.status == 401 or 402
            message = error.data
            if error.data and error.data.message
              if /^User is disabled.*/.test(error.data.message)
                message = "User is disabled!"
            $scope.validator.note = _(message)
          else
            message = "User is not register or have not been approval, please contact administrator."
            $scope.validator.note = _(message)
        successHandler = (data, status) ->
          authInfo = {
            username: authData.data.username    
            password: authData.data.password
          }
          $desktopLogin authInfo, () ->
            $scope.showLoading = false
            $scope.disableLogin = false
            location.hash = '#/dashboard/overview'
            location.reload()
        $http authData
          .then(successHandler, errorHandler)
        return
