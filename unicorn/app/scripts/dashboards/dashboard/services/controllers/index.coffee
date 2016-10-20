'use strict'

###*
 # @ngdoc function
 # @name Unicorn.dashboard.instance:ApplicationCtr
 # @description
 # # ApplicationCtr
 # Controller of the Unicorn
###
angular.module("Unicorn.dashboard.services")
  .controller "dashboard.services.ServicesCtr", ($scope, $http,
  $q, $window, $state, $dataLoader) ->
    serverURL = $window.$UNICORN.settings.serverURL
    servicesArg = '/workflow-request-types?enable=1'
    servicesURL = "#{serverURL}#{servicesArg}"
    $http.get(servicesURL)
      .success (data, status, headers) ->
        $scope.services = data
        if !$unicorn.wfTypesMap
          $unicorn.wfTypesMap = {}
          for service in data
            $unicorn.wfTypesMap[String(service.id)] = service.name
      .error (error) ->
        toastr.error _("Error at get services list.")

    $scope.dataLoading = false
    $scope.loadForm = (type, $event) ->
      if $scope.dataLoading
        return
      $scope.dataLoading = true
      $dataLoader($scope, type, 'modal')
      return
