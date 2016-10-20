'use strict'

angular.module('Unicorn.dashboard.ports')
  .controller 'dashboard.ports.PortDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state) ->
    $scope.currentId = $stateParams.portId

    $scope.detailItem = {
      overview: _("Base Info")
      name: _("Name")
      status: _("Status")
      rel_server: _("Relited Server")
      ip_addr: _("Floating IP")
      sec: _("Security Group")
      fixedip: _("Fixed IP")
      mac: _("Mac Address")
      subnet: _("Subnet")
    }

    serverURL = $window.$UNICORN.settings.serverURL

    $scope.detail_tabs = [
      {
        name: _('Overview')
        url: 'dashboard.ports.portId.overview'
        available: true
      }
    ]

    routerDetail = new $unicorn.DetailView()
    routerDetail.init($scope, {
      $stateParams: $stateParams
      $state: $state
      itemId: $scope.currentId
    })

    getPort = (portId) ->
      tenantId = $UNICORN.person.project.id
      subnets = $http.get "#{serverURL}/subnets?tenant_id=#{tenantId}"
      floatings = $http.get "#{serverURL}/floatingips"
      servers = $http.get "#{serverURL}/servers?tenant_id=#{tenantId}"
      securitys = $http.get "#{serverURL}/os-security-groups"
      portURL = $http.get "#{serverURL}/ports/#{portId}"
      $q.all([portURL, subnets, floatings, servers, securitys])
        .then (values) ->
          port = values[0].data
          floatingList = values[2].data
          subnetList = values[1].data
          serverList = values[3].data
          securityGroups = values[4].data
          # Prepare relatived resource
          subnetMap = {}
          connectedPort = {}
          serverIPMap = {}
          securityMap = {}
          for floatingip in floatingList
            if floatingip.port_id
              connectedPort[floatingip.port_id] = floatingip
          for subnet in subnetList
            subnetMap[subnet.id] = subnet
          for server in serverList.data
            addresses = JSON.parse server.addresses
            for key, value of addresses
              if value
                for addr in value
                  serverIPMap[addr.addr] = server
          for security in securityGroups
            securityMap[security.id] = security

          port.rel_servers = []
          port.secs = []
          if port.name == ''
            port.name = '-'
          # Inject subnet detail info into port.fixed_ips
          # Add relavied server into res_servers
          for fixed in port.fixed_ips
            if fixed
              if serverIPMap[fixed.ip_address]
                port.rel_servers.push serverIPMap[fixed.ip_address]
              fixed.subnet = subnetMap[fixed.subnet_id]
          if connectedPort[port.id]
            port.floating = connectedPort[port.id]
          for sec in port.security_groups
            if securityMap[sec]
              port.secs.push securityMap[sec]
          $scope.port_detail = port

    getPort($scope.currentId)
