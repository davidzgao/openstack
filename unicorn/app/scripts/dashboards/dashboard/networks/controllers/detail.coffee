'use strict'

angular.module('Unicorn.dashboard.networks')
  .controller 'dashboard.networks.NetworkDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state) ->
    $scope.currentId = $stateParams.networkId

    if $state.params.tab == 'subnet'
      $scope.is_subnet = true

    $scope.detailItem = {
      overview: _("Base Info")
      name: _("Name")
      status: _("Status")
      subnets: _("Subnets")
      network: _("Network")
      gateway: _("Gateway IP")
      ip_version: _("IP Version")
      cidr: _("CIDR Range")
      pool: _("Allocation Pools")
      ports: _("Ports")
    }

    $scope.subnetDetail = {
      name: _("Subnet Name")
      cidr: _("CIDR")
      action: _("Action")
      is_null: _("No subnet!")
      ip_address: _("IP Address")
      mac_address: _("Mac Address")
      instances: _("Relatived Instances")
      status: _("Status")
      port_name: _("Port Name")
    }

    serverURL = $window.$UNICORN.settings.serverURL

    $scope.detail_tabs = [
      {
        name: _('Overview')
        url: 'dashboard.networks.networkId.overview'
        available: true
        active: 'active'
      }
    ]

    networkDetail = new $unicorn.DetailView()
    networkDetail.init($scope, {
      $stateParams: $stateParams
      $state: $state
      itemId: $scope.currentId
    })

    getNetwork = (networkId) ->
      networkURL = $http.get "#{serverURL}/networks/#{networkId}"
      tenantId = $UNICORN.person.project.id
      subnetsURL = $http.get "#{serverURL}/subnets"
      $q.all([networkURL, subnetsURL])
        .then (values) ->
          networkDetail = values[0].data
          subnets = values[1].data
          subnetMap = {}
          for subnet in subnets
            subnetMap[subnet.id] = subnet
          for sub, index in networkDetail.subnets
            if subnetMap[sub]
              networkDetail.subnets[index] = subnetMap[sub]
          $scope.network_detail = networkDetail

    getSubnet = (networkId) ->
      tenantId = $UNICORN.person.project.id
      networksURL = $http.get "#{serverURL}/networks"
      portsURL = $http.get "#{serverURL}/ports"
      subnetURL = $http.get "#{serverURL}/subnets/#{networkId}"
      $q.all([networksURL, subnetURL, portsURL])
        .then (values) ->
          subnetDetail = values[1].data
          networks = values[0].data
          ports = values[2].data
          networkMap = {}
          portMap = {}
          for port in ports
            for ip in port.fixed_ips
              if portMap[ip.subnet_id]
                portMap[ip.subnet_id].push port
              else
                portMap[ip.subnet_id] = [port]
          for network in networks
            networkMap[network.id] = network
          if networkMap[subnetDetail.network_id]
            subnetDetail.network = networkMap[subnetDetail.network_id]
          if portMap[subnetDetail.id]
            subnetDetail.ports = portMap[subnetDetail.id]
          $scope.network_detail = subnetDetail

    if $scope.is_subnet
      getSubnet($scope.currentId)
    else
      getNetwork($scope.currentId)
