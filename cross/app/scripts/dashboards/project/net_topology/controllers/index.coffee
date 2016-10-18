'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.project.net_topology')
  .controller 'project.net_topology.NetTopologyCtr', ($scope, $http, $window, $q,
                                         $state, $interval, $templateCache,
                                         $compile, $animate) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.note =
      title: _("Network topology")

    params =
      params:
        tenant_id: $CROSS.person.project.id
    serverHttp = $cross.listServers $http, $window, (servers) ->
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
        info = utils.init(networks, subnets, routers, ports, servers)
        $scope.topology =
          netView: info


utils =
  _prepare_networks_: (networks, subnets, routers, ports, instances) ->
    # prepare subnets.
    subs = {}
    for sub in subnets
      subs["sub_#{sub.id}"] =
        "name": sub.name
        "enable_dhcp": sub.enable_dhcp
        "network_id": sub.network_id
        "gateway_ip": sub.gateway_ip
        "cidr": sub.cidr
        "id": sub.id

    # prepare networks
    nets = {}
    for net in networks
      nets["net_#{net.id}"] = net
      subnts = net.subnets
      nets["net_#{net.id}"].subnets = {}
      for sub in subnts
        nets["net_#{net.id}"].subnets["sub_#{sub}"] = subs["sub_#{sub}"] or {}

    # prepare routers
    rts = {}
    for router in routers
      rts["router_#{router.id}"] = router

    # prepare servers
    servers = {}
    for instance in instances
      servers["instance_#{instance.id}"] = instance

    # return networks dict
    return {
      networks: nets
      subnets: subs
      routers: rts
      servers: servers
      ports: ports
    }

  _shared_networks_: (nets) ->
    shared = []
    for net in nets
      if net['shared']
        shared.push net.id
    return shared

  init: (networks, subnets, routers, ports, instances) ->
    shared = utils._shared_networks_(networks)
    res = utils._prepare_networks_(networks, subnets, routers, ports, instances)
    res.shared = shared
    return res
