'use strict'

angular.module('Cross.project.instance')
  .controller 'project.instance.InstanceTopologyCtr', ($scope, $http,
  $q, $stateParams, $state, $window) ->
    serverUrl = $window.$CROSS.settings.serverURL

    params =
      params:
        tenant_id: $CROSS.person.project.id
    serverHttp = $http.get "#{serverUrl}/servers/#{$stateParams.instanceId}"
    netHttp = $http.get "#{serverUrl}/networks"
    routerHttp = $http.get "#{serverUrl}/routers", params
    portHttp = $http.get "#{serverUrl}/ports", params
    subHttp = $http.get "#{serverUrl}/subnets"
    $q.all [netHttp, subHttp, routerHttp, portHttp, serverHttp]
      .then (res) ->
        networks = res[0].data
        subnets = res[1].data
        routers = res[2].data
        ports = res[3].data
        server = res[4].data
        info = $cross.utils.init(networks, subnets, routers, ports, server)
        $scope.topology =
          netView: info

