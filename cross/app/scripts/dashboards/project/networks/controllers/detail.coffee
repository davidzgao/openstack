'use strict'

angular.module('Cross.project.networks')
  .controller 'project.networks.NetworkDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state, $detailShow, $selected,
  $updateNetworkCom) ->
    $scope.currentId = $stateParams.networkId
    $selected $scope
    $detailShow $scope

    if $state.params.tab == 'subnet'
      $scope.is_subnet = true

    $scope.detailItem = {
      overview: _("Base Info")
      name: _("Name")
      status: _("Status")
      subnets: _("Subnets")
      network: _("Network")
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

    serverURL = $window.$CROSS.settings.serverURL

    $scope.detail_tabs = [
      {
        name: _('Overview')
        url: 'project.networks.networkId.overview'
        available: true
        active: 'active'
      }
    ]

    $scope.detailKeySet = {
      detail: [
        {
          base_info:
            title: _("Detail Info")
            keys: [
              {
                key: 'name'
                value: _("Name")
                editable: true
                restrictions:
                  required: true
                  len: [4, 25]
                editAction: (key, value) ->
                  param = {
                    name: value
                  }
                  callback = {
                    success: (data) ->
                      $scope.$emit("update", data)
                      toastr.success _("Success to update network.")
                    error: (err) ->
                      toastr.error _("Failed to update network.")
                  }
                  type = "networks/#{$scope.currentId}"
                  $updateNetworkCom $scope, param, type, callback
              }, {
                key: 'id'
                value: _('ID')
              }, {
                key: 'status'
                value: _('Status')
                template: '<span class="status" ng-class="source.status"></span>{{source.status | i18n}}'
              }
            ]
        }
      ]
    }

    $scope.subKeySet = {
      detail: [
        {
          base_info:
            title: _("Detail Info")
            keys: [
              {
                key: 'name'
                value: _("Name")
                editable: true
                restrictions:
                  required: true
                  len: [4, 25]
                editAction: (key, value) ->
                  param = {
                    name: value
                  }
                  callback = {
                    success: (data) ->
                      $scope.$emit("update", data)
                      toastr.success _("Success to update subnet.")
                    error: (err) ->
                      toastr.error _("Failed to update subnet.")
                  }
                  type = "subnets/#{$scope.currentId}"
                  $updateNetworkCom $scope, param, type, callback
              }, {
                key: 'id'
                value: _('ID')
              }, {
                key: 'STATUS'
                value: _('Enable DHCP')
                template: '<span class="status" ng-class="source.status"></span>{{source.STATUS | i18n}}'
              }, {
                key: 'network_name'
                value: _('Network')
                template: '<span>{{source.network.name}}</span>'
              }, {
                key: 'gateway_ip'
                value: _('Gateway IP')
              }, {
                key: 'ip_version'
                value: _('IP Version')
              }, {
                key: 'cidr'
                value: _('CIDR Range')
              }, {
                key: 'pool'
                value: _('Allocation Pools')
                template: '<div ng-repeat="pool in source.allocation_pools" class="value-group"><span>start:{{pool.start}} - end:{{pool.end}}</span></div>'
              }
            ]
        }
      ]
    }

    getNetwork = (networkId) ->
      networkURL = $http.get "#{serverURL}/networks/#{networkId}"
      tenantId = $CROSS.person.project.id
      subnetsURL = $http.get "#{serverURL}/subnets?tenant_id=#{tenantId}"
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
      tenantId = $CROSS.person.project.id
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
          if subnetDetail.enable_dhcp
            subnetDetail.status = "ACTIVE"
            subnetDetail.STATUS = "Enable"
          else
            subnetDetail.status = "SHUTDOWN"
            subnetDetail.STATUS = "Disable"
          $scope.network_detail = subnetDetail

    if $scope.is_subnet
      getSubnet($scope.currentId)
    else
      getNetwork($scope.currentId)
