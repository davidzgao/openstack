'use strict'

angular.module('Cross.project.ports')
  .controller 'project.ports.PortCtr', ($scope, $http, $window,
  $q, $state, $tabs, $stateParams, $interval, $log) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.slug = _ "Ports"
    $scope.tabs = [{
      title: _('Ports')
      template: 'port.html'
      enable: true
    }]

    $tabs($scope)
    portTable = new PortTable($scope)
    portTable.init($scope, {
      $http: $http
      $window: $window
      $q: $q
      $state: $state
      $interval: $interval
      $log: $log
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
          link: 'project.ports.create'
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
          tag: 'button'
          name: 'detach'
          verbose: _("Detach Instance")
          enable: false
          action: $scope.remove
          confirm: _("Detach")
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

class PortTable extends $cross.TableView
  labileStatus: []
  slug: 'ports'
  pagingOptions: {
    pageSize: 100
    currentPage: 1
    showFooter: false
  }
  columnDefs: [
    {
      field: "fixed_ips"
      displayName: _("IP Address")
      cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="project.ports.portId.overview({portId:item.id})">{{item.fixed_ips[0].ip_address}}</a></div>'
    }
    {
      field: "network"
      displayName: _("Network")
      cellTemplate: '<div class="ngCellText">{{item.network.name}}</div>'
    }
    {
      field: "fixed_ips"
      displayName: _("Subnet")
      cellTemplate: '<div class=ngCellText ng-class="open"><li ng-repeat="fixed in item.fixed_ips">{{fixed.subnet.name}}</li><li ng-if="item.fixed_ips.length==0">{{"" | parseNull}}</li><div class="more-in-cell" title={{showAll}} ng-if="item.fixed_ips.length>1" ng-click="cellOpen($event.currentTarget)"></div></div>'
    }
    {
      field: "secs"
      displayName: _("Security Group")
      cellTemplate: '<div class=ngCellText ng-class="open"><li ng-repeat="sec in item.secs">{{sec.name}}</li><li ng-if="item.secs.length==0">{{"" | parseNull}}</li><div class="more-in-cell" title={{showAll}} ng-if="item.secs.length>1" ng-click="cellOpen($event.currentTarget)"></div></div>'
    }
    {
      field: "floating"
      displayName: _("FloatingIP")
      cellTemplate: '<div class="ngCellText">{{item.floating.floating_ip_address}}</div>'
    }
    {
      field: "rel_servers"
      displayName: _("Relatived Instance")
      cellTemplate: '<div class=ngCellText ng-class="open"><li ng-repeat="ser in item.rel_servers">{{ser.name}}</li><li ng-if="item.res_servers.length==0">{{"" | parseNull}}</li><div class="more-in-cell" title={{showAll}} ng-if="item.rel_servers.length>1" ng-click="cellOpen($event.currentTarget)"></div></div>'
    }
    {
      field: "status"
      displayName: _("Status")
      cellTemplate: '<div class="ngCellText status" ng-class="item.status"><i></i>{{item.STATUS}}</div>'
    }
  ]

  listData: ($scope, options, dataQueryOpts, callback) ->
    serverURL = $CROSS.settings.serverURL
    $http = options.$http
    $q = options.$q
    tenantId = $CROSS.person.project.id
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
        $scope.$on 'port-attach-instance', (event, data) ->
          angular.forEach $scope.portsOpts.data, (row, index) ->
            if row.id == data.portId
              row.rel_servers.push {name:data.instanceName} if row.rel_servers.length == 0
              row.STATUS = _ 'ACTIVE'
              row.status = 'active'

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
      , (error) ->
        callback []

  initialAction: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    $q = options.$q
    $interval = options.$interval
    $log = options.$log
    serverURL = $CROSS.settings.serverURL
    $scope.create = () ->
      $state.go "project.ports.create"
    $scope.attach = (link, enable) ->
      if not enable
        return
      portId = $scope.selectedItems[0].id
      $state.go "project.ports.pId.attach", {pId: portId}

    portGet = (portId, callback) ->
      $http.get "#{serverURL}/ports/#{portId}"
        .success (port) ->
          callback port
        .error (err, status) ->
          if status == 400
            callback undefined
          else
            $log.error err

    getLabileData = (portId) ->
      freshData = $interval(() ->
        portGet portId, (data) ->
          if data
            return
          else
            for item, index in $scope.portsOpts.data
              if item.id == portId
                $scope.portsOpts.data.splice index, 1
                $interval.cancel(freshData)
                return
      , 5000)

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
            getLabileData(portId)
          .error (data) ->
            toastr.error _("Failed detach to instance!")
            $state.go 'project.ports', {}, {reload: true}
      return
    $scope.delete = () ->
      deleteNetwork = (networkId, networkName) ->
        $http.delete "#{serverURL}/ports/#{networkId}"
          .success (data) ->
            toastr.success _("Success to delete port:") + networkName
            $state.go "project.ports", {}, {reload: true}
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
