'use strict'

angular.module 'Cross.admin.storage_node'
  .controller 'admin.storage_node.StorageCtr', ($scope, $http, $window,
  $q, $interval, $state) ->
    $scope.slug = _ 'Stroage'

    $scope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams) ->
      if toState.name == 'admin.storage_node'
        $state.go 'admin.storage_node.overview'

    $scope.tabs = [
      {
        title: _('Storage')
        url: 'admin.storage_node.overview'
        enable: true
      }
      {
        title: _('Monitor')
        url: 'admin.storage_node.monitor'
        enable: true
      }
    ]

    useFederator = $CROSS.settings.useFederator
    $scope.tabs[1].enable = false if useFederator

    $scope.isActiveTab = (url) ->
      if url == $state.current.name
        return true
