'use strict'

angular.module('Cross.project.networks')
  .controller 'project.networks.NetworkCtr', ($scope, $http, $window,
  $q, $state, $stateParams) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.slug = _ "Networks"
    $scope.tabs = [{
      title: _('Networks')
      template: 'network.html'
      enable: true
    }, {
      title: _('Subnets')
      template: 'subnet.html'
      enable: true
    }]

    $scope.currentTab = $scope.tabs[0]['template']
    $scope.onClickTab = (tab) ->
      params = null
      if tab.template == 'subnet.html'
        params = {tab: 'subnet'}
      $state.go "project.networks", params, {inherit: false}
    $scope.isActiveTab = (tabUrl) ->
      return tabUrl == $scope.currentTab
    if $stateParams.tab == 'subnet'
      $scope.currentTab = 'subnet.html'
    else
      $scope.currentTab = 'network.html'
  .controller 'project.networks.PriNetworkCtr', ($scope, $http,
  $window, $state, $q, $stateParams) ->
    networkTable = new NetworkTable($scope)
    networkTable.init($scope, {
      $http: $http
      $window: $window
      $q: $q
      $state: $state
      $stateParams: $stateParams
    })

    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      buttons: [
        {
          type: 'single'
          tag: 'a'
          name: 'create'
          verbose: _("Create Network")
          enable: true
          action: $scope.create
          link: 'project.networks.create'
        }
        {
          type: 'single'
          tag: 'a'
          name: 'create'
          verbose: _("Create Subnet")
          enable: false
          action: $scope.create_subnet
          link: 'project.networks.nId.create_subnet'
          restrict: {
            batch: false
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
  .controller 'project.networks.SubnetCtr', ($scope, $http,
  $window, $state, $q) ->
    networkTable = new SubTable($scope)
    networkTable.init($scope, {
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
          verbose: _("Create Subnet")
          enable: true
          action: $scope.create
          link: 'project.networks.create'
        }
        {
          type: 'single'
          tag: 'a'
          name: 'attach'
          verbose: _("Attach Router")
          enable: false
          action: $scope.attach
          link: 'project.networks.attach'
          restrict: {
            batch: false
            field: 'router'
            condition: 'not'
          }
        }
        {
          type: 'single'
          tag: 'button'
          name: 'detach'
          verbose: _("Disconnect Router")
          enable: false
          action: $scope.detach
          confirm: _("Disconnect")
          restrict: {
            batch: false
            field: 'router'
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
            condition: 'yes'
          }
        }
      ]
    }

class NetworkTable extends $cross.TableView
  labileStatus: []
  slug: 'networks'
  sortOpts: {
    sortingOrder: 'name'
    reverse: true
  }
  columnDefs: [
    {
      field: "name"
      displayName: _("Name")
      cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="project.networks.networkId.overview({networkId:item.id})">{{item.name}}</a></div>'
    }
    {
      field: "subnets"
      displayName: _("Subnets")
      cellTemplate: '<div class=ngCellText ng-class="open"><li ng-repeat="sub in item.subnets track by $index">{{sub.name}}</li><li ng-if="item.subnets.length==0">{{"" | parseNull}}</li><div class="more-in-cell" title={{showAll}} ng-if="item.subnets.length>1" ng-click="cellOpen($event.currentTarget)"></div></div>'
    }
    {
      field: "share"
      displayName: _("Is Shared")
      cellTemplate: '<div class="ngCellText" ng-class="item.shared"><i></i>{{item.SHARED}}</div>'
    }
    {
      field: "external"
      displayName: _("External")
      cellTemplate: '<div class="ngCellText"><i></i>{{item.external}}</div>'
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
    $state = options.$state
    tenantId = $CROSS.person.project.id
    networks = $http.get "#{serverURL}/networks"
    subnets = $http.get "#{serverURL}/subnets"
    $q.all([networks, subnets])
      .then (values) ->
        networkList = values[0].data
        subnetList = values[1].data
        subnetMap = {}
        networkMap = {}
        showNets = []
        for subnet in subnetList
          subnetMap[subnet.id] = subnet
        for network, index in networkList
          if network.tenant_id != tenantId
            if !network.shared
              if !network['router:external']
                continue
          network.SHARED = _ String(network.shared).toUpperCase()
          network.external = _ String(network['router:external']).toUpperCase()
          for sub, ind in network.subnets
            networkList[index].subnets[ind] = subnetMap[sub]
          showNets.push network
        callback showNets
      , (err) ->
        callback []

  initialAction: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    $q = options.$q
    serverURL = $CROSS.settings.serverURL
    $scope.create = () ->
      $state.go "project.networks.create"
    $scope.create_subnet = () ->
      networkId = $scope.selectedItems[0].id
      $state.go "project.networks.nId.createsubnet", {nId: networkId}
    $scope.delete = () ->
      network = $scope.selectedItems[0]
      networkUrl = "#{serverURL}/networks/#{network.id}"
      subnetsURL = []
      if network.subnets.length > 0
        for subnet in network.subnets
          subnetsURL.push $http.delete "#{serverURL}/subnets/#{subnet.id}"

        $q.all(subnetsURL)
          .then (data) ->
            toastr.success _("Success delete subnets.")
            $http.delete networkUrl
              .success (data) ->
                toastr.success _("Success delete network:") + network.name
                $state.go "project.networks", {}, {reload: true}
              .error (err) ->
                toastr.error _("Error at delete network.")
          , (err) ->
            if err.data
              if err.data.type == 'SubnetInUse'
                toastr.info _("The subnet of this network has been in use, can't delete.")
            else
              toastr.error _("Error at delete network.")
      else
        $http.delete networkUrl
          .success (data) ->
            toastr.success _("Success delete network:") + network.name
            $state.go "admin.internal_network", {}, {reload: true}
          .error (err) ->
            toastr.error _("Error at delete network.")
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
      tenantId = $CROSS.person.project.id
      if selectedItems[0].tenant_id != tenantId
        action.enable = false
        return
      if !restrict.field
        action.enable = true
      else
        if restrict.field
          if restrict.condition == 'yes'
            if selectedItems[0][restrict.field]
              action.enable = true
            else
              action.enable = false
          else
            if selectedItems[0][restrict.field]
              action.enable = false
            else
              action.enable = true
          return
    else if selectedItems.length > 0
      if action.restrict.batch
        action.enable = true
      else
        action.enable = false

class SubTable extends $cross.TableView
  labileStatus: []
  slug: 'subnets'
  sortOpts: {
    sortingOrder: 'name'
    reverse: true
  }
  columnDefs: [
    {
      field: "name"
      displayName: _("Name")
      cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="project.networks.networkId.overview({networkId:item.id})">{{item.name}}</a></div>'
    }
    {
      field: "network_name"
      displayName: _("Network")
      cellTemplate: '<div class="ngCellText">{{item.network.name}}</div>'
    }
    {
      field: "router"
      displayName: _("Connected Router")
      cellTemplate: '<div class="ngCellText">{{item.router.name}}</div>'
    }
    {
      field: "version"
      displayName: _("IP Version")
      cellTemplate: '<div class="ngCellText">IP v{{item.ip_version}}</div>'
    }
    {
      field: "cidr"
      displayName: _("CIDR Range")
      cellTemplate: '<div class="ngCellText">{{item.cidr}}</div>'
    }
    {
      field: "enable_dhcp"
      displayName: _("Enable DHCP")
      cellTemplate: '<div class="ngCellText">{{item.dhcp}}</div>'
    }
  ]

  listData: ($scope, options, dataQueryOpts, callback) ->
    serverURL = $CROSS.settings.serverURL
    $http = options.$http
    $q = options.$q
    $state = options.$state
    tenantId = $CROSS.person.project.id
    networks = $http.get "#{serverURL}/networks"
    subnets = $http.get "#{serverURL}/subnets"
    routers = $http.get "#{serverURL}/routers"
    ports = $http.get "#{serverURL}/ports"
    $q.all([networks, subnets, routers, ports])
      .then (values) ->
        networkList = values[0].data
        subnetList = values[1].data
        routerList = values[2].data
        portList = values[3].data
        relativedDevice = {}
        relavivedSubnet = {}
        for port in portList
          if !relativedDevice[port.device_id]
            relativedDevice[port.device_id] = []
          relativedDevice[port.device_id].push port
        for router in routerList
          if relativedDevice[router.id]
            ports = relativedDevice[router.id]
            for port in ports
              for sub in port.fixed_ips
                relavivedSubnet[sub.subnet_id] = router
        networkMap = {}
        for network, index in networkList
          networkMap[network.id] = network
        availableSub = []
        for subnet in subnetList
          subnet.network = networkMap[subnet.network_id]
          subnet.network_name = subnet.network.name
          if relavivedSubnet[subnet.id]
            subnet.router = relavivedSubnet[subnet.id]
          if subnet.enable_dhcp
            subnet.dhcp = _("Enable")
          else
            subnet.dhcp = _("Disable")
          if subnet.network['router:external']
            subnet.external = true
          if subnet.tenant_id != tenantId
            if not subnet.network['router:external'] and not \
            subnet.network['shared']
              continue
          availableSub.push subnet
        callback availableSub
      , (err) ->
        callback []

  initialAction: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    $q = options.$q
    serverURL = $CROSS.settings.serverURL
    $scope.create = () ->
      $state.go "project.networks.create"
    $scope.attach = () ->
      $state.go "project.networks.nId.attach", {nId: $scope.selectedItems[0].id}
    $scope.detach = () ->
      subnet = $scope.selectedItems[0]
      routerId = subnet.router.id
      routerURL = "#{serverURL}/routers/#{routerId}/remove_router_interface"
      body = {
        subnet_id: subnet.id
      }
      $http.put routerURL, body
        .success (data) ->
          toastr.success _("Success to detach router.")
          $state.go "project.networks", {tab: 'subnet'}, {reload: true}
        .error (err) ->
          toastr.error _("Failed to detach router.")

    $scope.delete = () ->
      network = $scope.selectedItems[0]
      subnetUrl = "#{serverURL}/subnets/#{network.id}"
      $http.delete subnetUrl
        .success (data) ->
          toastr.success _("Success to delete subnet: ") + network.name
        .error (err) ->
          if err.type == 'SubnetInUse'
            toastr.info _("Subnet in use, could not be delete.")
          else
            toastr.error _("Failed to delete subnet: ") + network.name
      $state.go "project.networks", {tab: 'subnet'}, {reload: true}

    $scope.openGateway = (link, enable) ->
      if not enable
        return false
      if $scope.selectedItems.length != 1
        return false
      $state.go link, {rId: $scope.selectedItems[0].id}

    $scope.clearGateway = () ->
      routerURL = "#{serverURL}/routers/#{$scope.selectedItems[0].id}"
      param = {
        external_gateway_info: null
      }
      $http.put routerURL, param
        .success (data) ->
          toastr.success _("Success clear external network.")
          $state.go 'project.routers', {}, {reload: true}
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
      tenantId = $CROSS.person.project.id
      if selectedItems[0].tenant_id != tenantId
        action.enable = false
        return
      if !restrict.field
        if selectedItems[0].external
          action.enable = false
          return
        else
          action.enable = true
      else
        if restrict.field
          if restrict.condition == 'yes'
            if selectedItems[0][restrict.field]
              action.enable = true
            else
              action.enable = false
          else
            if selectedItems[0][restrict.field]
              action.enable = false
            else
              action.enable = true
          if selectedItems[0].external
            action.enable = false
          return
    else if selectedItems.length > 0
      if action.restrict.batch
        action.enable = true
      else
        action.enable = false
