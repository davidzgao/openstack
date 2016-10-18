'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.admin.info')
  .controller 'admin.info.InfoCtr', ($scope, $http, $window, $q,
                                     $state, $interval, $templateCache,
                                     $compile, $animate) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.note =
      title: _("System info")
      service:
        down: _("Service down")
        enabled: _("Service enabled")
        disabled: _("Service disabled")

    nServiceHttp = $http.get "#{serverUrl}/os-services"
    cServiceHttp = $http.get "#{serverUrl}/cinder/os-services"
    $q.all [nServiceHttp, cServiceHttp]
      .then (res) ->
        nServices = res[0].data
        cServices = res[1].data
        serviceDict = {}
        for service in nServices
          if not serviceDict[service.host]
            serviceDict[service.host] = []
          item =
            name: service.binary
            status: if service.state == 'down' then 'down' else service.status
          serviceDict[service.host].push item
        for service in cServices
          if not serviceDict[service.host]
            serviceDict[service.host] = []
          item =
            name: service.binary
            state: service.state
            status: service.status
          serviceDict[service.host].push item
        $scope.services = serviceDict
