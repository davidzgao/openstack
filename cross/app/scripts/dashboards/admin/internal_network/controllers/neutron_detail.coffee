'use strict'

angular.module('Cross.admin.network')
  .controller 'admin.network.NetworkDetailCtr', ($scope, $http,
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
      gateway: _("Gateway IP")
      ip_version: _("IP Version")
      cidr: _("CIDR Range")
      pool: _("Allocation Pools")
      ports: _("Ports")
      shared: _("Is Shared")
      public: _("Public Network")
      network_type: _("Network Type")
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
      dns_servers: _("DNS name servers")
    }

    serverURL = $window.$CROSS.settings.serverURL

    $scope.detail_tabs = [
      {
        name: _('Overview')
        url: 'admin.network.networkId.overview'
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
              }, {
                key: 'project'
                value: _('Project')
                template: '<a ui-sref="admin.project.projId.overview({projId:source.tenant_id})">{{source.project.name}}</a>'
              }, {
                key: 'network_type'
                value: _('Network Type')
                template: '<span>{{source["provider:network_type"]}}</span>'
              }, {
                key: 'shared'
                value: _('Is Shared')
                editable: true
                template: '<span>{{source[title.key]?"Public":"Private" | i18n}}</span>'
                editType: 'select'
                default: [{
                  text: _("Public")
                  value: true
                }, {
                  text: _("Private")
                  value: false
                }]
                editAction: (key, value) ->
                  param = {
                    shared: value
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
                key: 'router:external'
                value: _('External')
                template: '<span>{{source[title.key]?"External":"Intranet" | i18n}}</span>'
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
                key: 'status'
                value: _('Enable DHCP')
                template: '<span class="status" ng-class="source.status"></span>{{source.STATUS | i18n}}'
              }, {
                key: 'network_name'
                value: _('Network')
                template: '<span>{{source.network.name}}</span>'
              }, {
                key: 'gateway_ip'
                value: _('Gateway IP')
                restrictions:
                  required: true
                  ip: true
                editAction: (key, value) ->
                  param = {
                    gateway_ip: value
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
                key: 'ip_version'
                value: _('IP Version')
              }, {
                key: 'cidr'
                value: _('CIDR Range')
              }, {
                key: 'pool'
                value: _('Allocation Pools')
                template: '<div ng-repeat="pool in source.allocation_pools" class="value-group"><span>start:{{pool.start}} - end:{{pool.end}}</span></div>'
              }, {
                key: 'servers'
                value: _ 'DNS name servers'
                editable: true
                editAction: (key, value) ->
                  if typeof value == 'object'
                    return
                  if value.indexOf(',')
                    ips = []
                    ipsT = value.split(',')
                    for ip in ipsT
                      ips.push ip.trim()
                  else
                    ips = [value]
                  param = {
                    'dns_nameservers': ips
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
              }
            ]
        }
      ]
    }

    getNetwork = (networkId) ->
      networkURL = $http.get "#{serverURL}/networks/#{networkId}"
      subnetsURL = $http.get "#{serverURL}/subnets"
      projectsURL = $http.get "#{serverURL}/projectsV3"
      $q.all([networkURL, subnetsURL, projectsURL])
        .then (values) ->
          networkDetail = values[0].data
          subnets = values[1].data
          projects = values[2].data.data
          subnetMap = {}
          projectMap = {}
          for project in projects
            projectMap[project.id] = project
          for subnet in subnets
            subnetMap[subnet.id] = subnet
          for sub, index in networkDetail.subnets
            if subnetMap[sub]
              networkDetail.subnets[index] = subnetMap[sub]
          if projectMap[networkDetail.tenant_id]
            networkDetail.project = projectMap[networkDetail.tenant_id]
          $scope.network_detail = networkDetail

    getSubnet = (networkId) ->
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
          subnetDetail.servers = subnetDetail.dns_nameservers.join(',')
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
