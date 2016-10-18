'use strict'

angular.module('Cross.project.lbaas')
  .controller 'project.lbaas.LBDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state, $detailShow, $selected) ->
    $scope.currentId = $stateParams.lbId
    $selected $scope
    $detailShow $scope

    $scope.detailItem = {
      name: _("Name")
      status: _("Status")
      subnet: _("Subnet")
    }
    serverURL = $window.$CROSS.settings.serverURL

    $scope.poolUpdate = (poolId, param) ->
      poolURL = "#{serverURL}/lb/pools/#{poolId}"
      $http.put poolURL, param
        .success (pool) ->
          toastr.success _("Success to update load balancer.")
          if param.lb_method
            $scope.pool_detail.lb_method = pool.lb_method
            $scope._LB_METHOD = pool.lb_method
          if param.name
            $scope.pool_detail.name = pool.name
        .error (err) ->
          toastr.error _("Failed to update load balancer.")
          if param.lb_method
            $scope.pool_detail.lb_method = $scope._LB_METHOD

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
                  $scope.poolUpdate $scope.currentId, param
              }
              {
                key: 'id'
                value: _('ID')
                editable: false
              }
              {
                key: 'subnet_name'
                value: _('Subnet')
              }
              {
                key: 'provider'
                value: _('Provider')
              }
              {
                key: 'protocol'
                value: _('Protocol')
              }
              {
                key: 'lb_method'
                value: _('LB Method')
                editable: true
                editType: 'select'
                default: [{
                  text: _("ROUND_ROBIN")
                  value: "ROUND_ROBIN"
                }, {
                  text: _("LEAST_CONNECTIONS")
                  value: "LEAST_CONNECTIONS"
                }, {
                  text: _("SOURCE_IP")
                  value: "SOURCE_IP"
                }]
                editAction: (key, value) ->
                  param = {
                    lb_method: value
                  }
                  $scope.poolUpdate $scope.currentId, param
              }
            ]
          vip_info:
            hidden: 'vip_id'
            title: _("VIP Info")
            keys: [
              {
                key: 'vip_addr'
                value: _ 'vip_address'
              }
              {
                key: 'vip_floatingip'
                value: _ 'vip_floatingip'
              }
              {
                key: 'vip_protocol'
                value: _ 'Protocol'
              }
              {
                key: 'protocol_port'
                value: _ 'Protocol Port'
              }
              {
                key: 'session_persistence'
                value: _ 'Session Persistence'
              }
              {
                key: 'vip_limit'
                value: _ 'Connection Limit'
              }
            ]
        }
      ]
    }

    $scope.detail_tabs = [
      {
        name: _('Overview')
        url: 'project.lbaas.lbId.overview'
        available: true
      }
    ]

    getLB = (poolId) ->
      tenantId = $CROSS.person.project.id
      subnets = $http.get "#{serverURL}/subnets?tenant_id=#{tenantId}"
      floatings = $http.get "#{serverURL}/floatingips"
      portURL = $http.get "#{serverURL}/lb/pools/#{poolId}"
      vipURL = $http.get "#{serverURL}/lb/vips?pool_id=#{poolId}"
      servers = $http.get "#{serverURL}/lb/members?pool_id=#{poolId}"
      $q.all([portURL, subnets, floatings, vipURL, servers])
        .then (values) ->
          pool = values[0].data
          floatingList = values[2].data
          subnetList = values[1].data
          vipList = values[3].data
          serverList = values[4].data
          # Prepare relatived resource
          subnetMap = {}
          floatingMap = {}
          for subnet in subnetList
            subnetMap[subnet.id] = subnet
          if vipList.length > 0
            vip = vipList[0]
          for floating in floatingList
            if vip
              if floating.port_id == vip.port_id
                vip.floating_ip_address = floating.floating_ip_address
                break
          pool.members = serverList
          # Release the releatived resource
          serverList = undefined
          subnetList = undefined
          floatingList = undefined
          if subnetMap[pool.subnet_id]
            pool.subnet = subnetMap[pool.subnet_id]
            pool.subnet_name = pool.subnet.name + ':' + pool.subnet.cidr
          if vip
            pool.vip_addr = vip.address
            pool.vip_floatingip = vip.floating_ip_address
            pool.vip_protocol = vip.protocol
            pool.protocol_port = vip.protocol_port
            pool.session_persistence = vip.session_persistence.type
            pool.vip_limit = vip.connection_limit
          $scope._LB_METHOD = _ pool.lb_method
          $scope.pool_detail = pool

    getLB($scope.currentId)
