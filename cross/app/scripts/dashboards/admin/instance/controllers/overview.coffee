'use strict'

angular.module('Cross.admin.instance')
  .controller 'admin.instance.InstanceOverviewCtr', ($scope, $http,
  $window, $q, $stateParams, $state, $updateDetail, $watchDeleted,
  $updateServer, $serverDetail) ->
    $scope.currentId = $stateParams.instanceId

    $serverDetail $scope, $updateDetail, $watchDeleted,
    $state, $updateServer

    $scope.update = () ->
      $scope.getServer()

    $scope.getServer()
