'use strict'

angular.module('Cross.admin.instance')
  .controller 'admin.instance.InstanceLogCtr', ($scope, $http,
                                            $window, $q, $stateParams, $state) ->
    currentInstance = $stateParams.instanceId
    $scope.logLength = 35
    $scope.queryAction = _("Get Full Log")

    $scope.getLog = (length) ->
      $cross.serverLog $http, $window, currentInstance, length, (data) ->
        if data.length == 0
          $scope.log = 'null'
        else
          $scope.log = data

    $scope.getLog $scope.logLength

    $scope.getFullLog = () ->
      if $scope.logLength == 0
        return
      $scope.log = null
      $scope.logLength = 0
      $scope.getLog $scope.logLength
