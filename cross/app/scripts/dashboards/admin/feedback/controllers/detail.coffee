'use strict'

angular.module('Cross.admin.feedback')
  .controller 'admin.feedback.FeedbackDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state, $selected) ->
    $scope.currentId = $stateParams.feedId
    $selected $scope
    if $scope.currentId
      $scope.detail_show = "detail_show"
    else
      $scope.detail_show = "detail_hide"

    $scope.feedback_tabs = [
      {
        name: _("Overview")
        url: 'admin.feedback.feedId.overview'
        available: true
      }
      {
        name: _("Reply")
        url: 'admin.feedback.feedId.reply'
        available: true
      }
    ]

    $scope.checkActive = () ->
      for tab in $scope.feedback_tabs
        if tab.url == $state.current.name
          tab.active = 'active'
        else
          tab.active = ''

    $scope.panle_close = () ->
      $state.go 'admin.feedback'
      $scope.detail_show = false

    $scope.checkActive()

    $scope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams) ->
      $scope.checkActive()
