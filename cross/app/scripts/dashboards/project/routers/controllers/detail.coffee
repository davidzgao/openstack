'use strict'

angular.module('Cross.project.routers')
  .controller 'project.routers.RouterDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state, $detailShow, $selected,
  $updateNetworkCom) ->
    $scope.currentId = $stateParams.routerId
    $selected $scope
    $detailShow $scope

    $scope.detailItem = {
      overview: _("Base Info")
      name: _("Name")
      status: _("Status")
      gateway: _("External Network")
    }

    serverURL = $window.$CROSS.settings.serverURL

    $scope.detail_tabs = [
      {
        name: _('Overview')
        url: 'project.routers.routerId.overview'
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
                      toastr.success _("Success to update router.")
                    error: (err) ->
                      toastr.error _("Failed to update router.")
                  }
                  type = "routers/#{$scope.currentId}"
                  $updateNetworkCom $scope, param, type, callback
              }, {
                key: 'id'
                value: _('ID')
              }, {
                key: 'status'
                value: _('Status')
                template: '<span class="status" ng-class="source.status"></span>{{source.status | i18n}}'
              }, {
                key: 'external_network'
                value: _('External Network')
              }
            ]
        }
      ]
    }

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
