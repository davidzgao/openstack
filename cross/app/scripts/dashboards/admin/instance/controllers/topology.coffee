'use strict'

angular.module('Cross.admin.instance')
  .controller 'admin.instance.InstanceTopologyCtr', ($scope, $http,
  $q, $stateParams, $state, $window) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $http.get "#{serverUrl}/servers/#{$stateParams.instanceId}"
      .success (data) ->
        params =
          params:
            tenant_id: data.tenant_id
        internalNetHttp = $http.get "#{serverUrl}/networks?tenant_id=\
                          #{data.tenant_id}"
        externalNetHttp = $http.get "#{serverUrl}/networks?router:external=\
                          true"
        routerHttp = $http.get "#{serverUrl}/routers", params
        portHttp = $http.get "#{serverUrl}/ports", params
        internalSubHttp = $http.get "#{serverUrl}/subnets?tenant_id=\
                          #{data.tenant_id}"
        subHttp = $http.get "#{serverUrl}/subnets"
        $q.all [internalNetHttp, internalSubHttp,
                routerHttp, portHttp, externalNetHttp,
                subHttp]
          .then (res) ->
            externalSub = []
            networks = res[0].data
            subnets = res[1].data
            for item in res[4].data
              networks.push item
              externalSub.push item.id
            for item in res[5].data
                subnets.push item if item.network_id in externalSub
            routers = res[2].data
            ports = res[3].data
            server = data
            info = $cross.utils.init(networks, subnets, routers, ports, server)
            $scope.topology =
              netView: info

