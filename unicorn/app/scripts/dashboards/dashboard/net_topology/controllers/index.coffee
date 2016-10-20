'use strict'

angular.module('Unicorn.dashboard.net_topology')
  .controller 'dashboard.net_topology.NetTopologyCtr', ($scope, $http, $window, $q,
                                         $state, $interval, $templateCache,
                                         $compile, $animate) ->
    serverUrl = $window.$UNICORN.settings.serverURL


    $scope.note =
      title: _ "Network Topology"

    params =
      params:
        tenant_id: $UNICORN.person.project.id
    serverHttp = $unicorn.listServers $http, $window, (servers) ->
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
        servers = res[4].data.data
        info = $unicorn.utils.initTopology(networks, subnets, routers, ports, servers)
        $scope.topology =
          netView: info

