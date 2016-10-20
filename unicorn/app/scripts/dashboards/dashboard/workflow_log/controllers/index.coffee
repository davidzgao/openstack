'use strict'

angular.module('Unicorn.dashboard.workflow_log')
  .controller 'dashboard.workflow_log.WorkflowLogCtr', ($scope, $http, $window,
  $q, $state) ->
    $scope.slug = _ 'Workflow Log'
    $scope.tabs = [
      {
        title: _('Unread')
        template: 'unread.tpl.html'
        enable: true
      }
      {
        title: _('Read')
        template: 'read.tpl.html'
        enable: true
      }
    ]

    $scope.currentTab = 'unread.tpl.html'

    $scope.onClickTab = (tab) ->
      $state.go 'dashboard.workflow_log'
      $scope.currentTab = tab.template

    $scope.isActiveTab = (tabUrl) ->
      return tabUrl == $scope.currentTab
