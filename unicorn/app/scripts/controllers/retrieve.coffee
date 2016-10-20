'use strict'

angular.module('Unicorn.retrieve', [])
  .controller 'RetrieveCtrl', ($scope, $http, $q, $rootScope,
  $state, $window) ->

    $scope.note = {
      header: _("Retrieve Password")
      email: _("Register Email")
      submit: _("Submit")
      congratulation: _("Successed to send email!")
    }

    title = $window.$UNICORN.settings.websiteTitle || 'ECONE'
    $rootScope.title = "#{title} - #{$scope.note.header}"

    $scope.registerMainHeight = $(window).height()
    angular.element(window).smartresize ->
      $scope.registerMainHeight = $(window).height()

    $scope.user = {}
    $scope.validateStatus = {}

    $scope.fieldDisabled = false
    $scope.registerSuccess = false

    emailCheck = (email) ->
      if !email
        $scope.validateStatus.email = undefined
        $scope.emailStatus = ''
        return
      emailRegExp = /\S+@\S+\.\S+/
      if emailRegExp.test(email)
        $scope.validateStatus.email = 'valid'
        $scope.emailStatus = 'correct'
        $scope.inputTips = ''
      else
        $scope.validateStatus.email = 'invalid'
        $scope.emailStatus = 'error'
        $scope.inputTips = _ "Please input an effective email."

    serverURL = $window.$UNICORN.settings.serverURL

    $scope.fieldBlur = (field) ->
      emailCheck $scope.user.email

    $scope.retireveSubmit = () ->
      email = $scope.user.email
      emailCheck(email)
      if !$scope.validateStatus.email
        $scope.inputTips = _ "Please input an effective email."
      else
        if $scope.validateStatus.email == 'valid'
          $scope.fieldDisabled = true
          $scope.showLoading = true
          data = {email: $scope.user.email}
          $http.post "#{serverURL}/password/retrieve", data
          .success (data) ->
            $scope.fieldDisabled = false
            $scope.showLoading = false
            $scope.registerSuccess = true
          .error (err) ->
            $scope.fieldDisabled = false
            $scope.showLoading = false
            $scope.inputTips = _ err.error
        else
          $scope.inputTips = _ "Please input an effective email."

    $scope.goBack = () ->
      $state.go 'login'
