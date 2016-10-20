'use strict'

angular.module('Unicorn.dashboard.routers')
  .controller 'dashboard.routers.RouterDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state) ->
    $scope.currentId = $stateParams.routerId

    $scope.detailItem = {
      overview: _("Base Info")
      name: _("Name")
      status: _("Status")
      gateway: _("External Network")
    }

    serverURL = $window.$UNICORN.settings.serverURL

    routerDetail = new $unicorn.DetailView()
    routerDetail.init($scope, {
      $stateParams: $stateParams
      $state: $state
      itemId: $scope.currentId
    })

    $scope.detail_tabs = [
      {
        name: _('Overview')
        url: 'dashboard.routers.routerId.overview'
        available: true
      }
    ]

    $scope.subnetDetail = {
      name: _("Subnet Name")
      cidr: _("CIDR")
      action: _("Action")
      is_null: _("No subnet!")
      ip_address: _("IP Address")
      net_name: _("Network Name")
      sub_name: _("Subnet Name")
      detach: _("Disconnect")
      detach_tips: _("Confirm to detach subnet: ")
    }

    $scope.detachNet = (subnetId) ->
      routerId = $scope.currentId
      routerURL = "#{serverURL}/routers/#{routerId}/remove_router_interface"
      body = {
        subnet_id: subnetId
      }
      $http.put routerURL, body
        .success (data) ->
          toastr.success _("Success to detach subnet.")
          for sub, index in $scope.conSubs
            if subnetId == sub.id
              $scope.conSubs.splice(index, 1)
              break
        .error (err) ->
          toastr.error _("Failed to detach subnet.")

    router = $http.get "#{serverURL}/routers/#{$scope.currentId}"
    ports = $http.get "#{serverURL}/ports?device_id=#{$scope.currentId}"
    subnets = $http.get "#{serverURL}/subnets"
    networks = $http.get "#{serverURL}/networks"
    $q.all([router, ports, subnets, networks])
      .then (values) ->
        routerDetail = values[0].data
        portList = values[1].data
        subnetList = values[2].data
        networkList = values[3].data
        if routerDetail.external_gateway_info
          routerDetail.external_network = _ "Connected"
        else
          routerDetail.external_network = _ "Disconnected"
        $scope.router_detail = routerDetail
        connectedSubnets = {}
        for port in portList
          if port.device_owner == 'network:router_gateway'
            continue
          for sub in port.fixed_ips
            connectedSubnets[sub.subnet_id] = sub
        networkMap = {}
        for network in networkList
          networkMap[network.id] = network
        conSubs = []
        for subnet in subnetList
          if connectedSubnets[subnet.id]
            subnet.router_ip = connectedSubnets[subnet.id].ip_address
            subnet.network_name = networkMap[subnet.network_id].name
            conSubs.push subnet
        $scope.conSubs = conSubs
