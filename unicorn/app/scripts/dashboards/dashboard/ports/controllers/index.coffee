'use strict'

angular.module('Unicorn.dashboard.ports')
  .controller 'dashboard.ports.PortCtr', ($scope, $http, $window,
  $q, $state) ->
    serverUrl = $window.$UNICORN.settings.serverURL

    $scope.slug = _ "Ports"

    portTable = new PortTable($scope)
    portTable.init($scope, {
      $http: $http
      $window: $window
      $q: $q
      $state: $state
    })

    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      buttons: [
        {
          type: 'single'
          tag: 'a'
          name: 'create'
          verbose: _("Create Port")
          enable: true
          action: $scope.create
          link: 'dashboard.ports.create'
        }
        {
          type: 'action'
          tag: 'a'
          name: 'attach'
          verbose: _("Attach Instance")
          enable: false
          action: $scope.attach
          restrict: {
            batch: false
            field: 'rel_servers'
            condition: 'not'
          }
        }
        {
          type: 'action'
          tag: 'a'
          name: 'detach'
          verbose: _('Detach Instance')
          enable: false
          action: $scope.remove
          confirm: _('Detach')
          restrict: {
            batch: false
            field: 'rel_servers'
            condition: 'yes'
          }
        }
        {
          type: 'action'
          tag: 'button'
          name: 'del'
          verbose: _("Delete")
          enable: false
          action: $scope.delete
          confirm: _("Delete")
          restrict: {
            batch: false
          }
        }
      ]
    }

class PortTable extends $unicorn.TableView
  labileStatus: []
  slug: 'ports'
  pagingOptions: {
    pageSize: 100
    currentPage: 1
    showFooter: false
  }
  sortOpts: {
    sortingOrder: 'name'
    reverse: true
  }
  columnDefs: [
    {
      filed: "ip"
      displayName: _("IP Address")
      cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="dashboard.ports.portId.overview({portId:item.id})">{{item.fixed_ips[0].ip_address}}</a></div>'
    }
    {
      field: "network"
      displayName: _("Network")
      cellTemplate: '<div class="ngCellText">{{item.network.name}}</div>'
    }
    {
      filed: "subnet"
      displayName: _("Subnet")
      cellTemplate: '<div class=ngCellText ng-class="open"><li ng-repeat="fixed in item.fixed_ips">{{fixed.subnet.name}}</li><li ng-if="item.fixed_ips.length==0">{{"" | parseNull}}</li><div class="more-in-cell" title={{showAll}} ng-if="item.fixed_ips.length>1" ng-click="cellOpen($event.currentTarget)"></div></div>'
    }
    {
      filed: "security_group"
      displayName: _("Security Group")
      cellTemplate: '<div class=ngCellText ng-class="open"><li ng-repeat="sec in item.secs">{{sec.name}}</li><li ng-if="item.secs.length==0">{{"" | parseNull}}</li><div class="more-in-cell" title={{showAll}} ng-if="item.secs.length>1" ng-click="cellOpen($event.currentTarget)"></div></div>'
    }
    {
      filed: "floatingip"
      displayName: _("FloatingIP")
      cellTemplate: '<div class="ngCellText">{{item.floating.floating_ip_address | parseNull}}</div>'
    }
    {
      filed: "instance"
      displayName: _("Relatived Instance")
      cellTemplate: '<div class=ngCellText ng-class="open"><li ng-repeat="ser in item.rel_servers">{{ser.name}}</li><li ng-if="item.res_servers.length==0">{{"" | parseNull}}</li><div class="more-in-cell" title={{showAll}} ng-if="item.rel_servers.length>1" ng-click="cellOpen($event.currentTarget)"></div></div>'
    }
    {
      filed: "status"
      displayName: _("Status")
      cellTemplate: '<div class="ngCellText status" ng-class="item.status"><i></i>{{item.STATUS}}</div>'
    }
  ]

  listData: ($scope, options, dataQueryOpts, callback) ->
    serverURL = $UNICORN.settings.serverURL
    $http = options.$http
    $q = options.$q
    tenantId = $UNICORN.person.project.id
    ports = $http.get "#{serverURL}/ports?tenant_id=#{tenantId}"
    subnets = $http.get "#{serverURL}/subnets?tenant_id=#{tenantId}"
    networks = $http.get "#{serverURL}/networks?tenant_id=#{tenantId}"
    floatings = $http.get "#{serverURL}/floatingips"
    servers = $http.get "#{serverURL}/servers?tenant_id=#{tenantId}"
    securitys = $http.get "#{serverURL}/os-security-groups"
    $q.all([ports, floatings, subnets, servers, securitys, networks])
      .then (values) ->
        portList = values[0].data
        floatingList = values[1].data
        subnetList = values[2].data
        serverList = values[3].data
        securityGroups = values[4].data
        networkList = values[5].data
        # Prepare relatived resource
        subnetMap = {}
        connectedPort = {}
        serverIPMap = {}
        securityMap = {}
        networkMap = {}
        for network in networkList
          networkMap[network.id] = network
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

        realPorts = []
        for port in portList
          # Filter interface from all ports
          if networkMap[port.network_id]
            port.network = networkMap[port.network_id]
          if port.device_owner != ''
            if port.device_owner.indexOf('compute') < 0
              continue
          port.rel_servers = []
          port.secs = []
          if port.name == ''
            name = _ "Port"
            port.name = "#{name}-#{port.fixed_ips[0].ip_address}"
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
          realPorts.push port
        callback realPorts, realPorts.length
      , (err) ->
        callback []

  initialAction: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    $q = options.$q
    serverURL = $UNICORN.settings.serverURL
    $scope.create = () ->
      $state.go "dashboard.ports.create"
    $scope.attach = () ->
      portId = $scope.selectedItems[0].id
      $state.go "dashboard.ports.pId.attach", {pId: portId}
    $scope.remove = (link, enable) ->
      if not enable
        return
      portId = $scope.selectedItems[0].id
      for item in $scope.items
        if item.id == portId
          deviceId = item.device_id
          break
      if deviceId
        attachURL = "#{serverURL}/servers/#{deviceId}/os-interface"
        detachURL = "#{attachURL}/#{portId}"
        $http.delete detachURL
          .success (data) ->
            toastr.success _("Success detach to instance!")
            $state.go 'dashboard.ports', {}, {reload: true}
          .error (data) ->
            toastr.error _("Failed detach to instance!")
            $state.go 'dashboard.ports', {}, {reload: true}
      return

    $scope.delete = () ->
      deleteNetwork = (networkId, networkName) ->
        $http.delete "#{serverURL}/ports/#{networkId}"
          .success (data) ->
            toastr.success _("Success to delete port:") + networkName
            $state.go "dashboard.ports", {}, {reload: true}
      network = $scope.selectedItems[0]
      networkUrl = "#{serverURL}/ports/#{network.id}"
      $http.get(networkUrl)
        .success (data) ->
          deleteNetwork data.id, data.name
    super($scope, options)

  itemChange: (newVal, oldVal, $scope, options) ->
    obj = options.$this
    if newVal != oldVal
      selectedItems = []
      for item in newVal
        if item.isSelected == true
          selectedItems.push item
      $scope.selectedItems = selectedItems

      for action in $scope.actionButtons.buttons
        if !action.restrict
          continue
        obj.judgeAction(action, selectedItems)

  judgeAction: (action, selectedItems) ->
    restrict = {
      batch: true
      field: null
      condition: null
    }
    for key, value of action.restrict
      restrict[key] = value

    if selectedItems.length == 0
      action.enable = false
      return
    else if selectedItems.length == 1
      if !restrict.field
        action.enable = true
      else
        if restrict.field
          if restrict.condition == 'yes'
            if selectedItems[0][restrict.field].length
              action.enable = true
            else
              action.enable = false
          else
            if selectedItems[0][restrict.field].length
              action.enable = false
            else
              action.enable = true
          return
    else if selectedItems.length > 0
      if action.restrict.batch
        action.enable = true
      else
        action.enable = false
