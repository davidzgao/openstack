'use strict'

angular.module('Cross.admin.network')
  .controller 'admin.network.NetworkCtr', ($scope, $http,
  $window, $q, $state, $stateParams) ->
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
      $state.go "admin.network", params, {inherit: false}
    $scope.isActiveTab = (tabUrl) ->
      return tabUrl == $scope.currentTab
    if $stateParams.tab == 'subnet'
      $scope.currentTab = 'subnet.html'
    else
      $scope.currentTab = 'network.html'
  .controller 'admin.network.PriNetworkCtr', ($scope, $http,
  $window, $state, $q, $stateParams) ->
    networkTable = new AdminNetworkTable($scope)
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
          link: 'admin.network.create'
        }
        {
          type: 'single'
          tag: 'a'
          name: 'create'
          verbose: _("Create Subnet")
          enable: false
          action: $scope.create_subnet
          link: 'admin.network.nId.create_subnet'
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
  .controller 'admin.network.SubnetCtr', ($scope, $http,
  $window, $state, $q) ->
    $scope.addition = (subId, enable) ->
      if enable
        enable_dhcp = false
      else
        enable_dhcp = true
      param = {
        enable_dhcp: enable_dhcp
      }
      subnetURL = $CROSS.settings.serverURL + '/subnets/' + subId
      $http.put subnetURL, param
        .success (data, status) ->
          if data
            for sub, index in $scope.items
              if sub.id == data.id
                if data.enable_dhcp
                  sub.condition = 'on'
                else
                  sub.condition = 'off'
                break
          toastr.success _("Success to update subnet DHCP.")
        .error (err) ->
          for sub, index in $scope.items
            if sub.id == subId
              if param.enable_dhcp
                sub.condition = 'off'
              else
                sub.condition = 'on'
              break
          toastr.error _("Failed to update subnet DHCP.")
      return
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
          link: 'admin.network.create'
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

class AdminNetworkTable extends $cross.TableView
  labileStatus: []
  slug: 'networks'
  columnDefs: [
    {
      field: "name"
      displayName: _("Name")
      cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="admin.network.networkId.overview({networkId:item.id})">{{item.name}}</a></div>'
    }
    {
      field: "project"
      displayName: _("Project")
      cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="admin.project.projId.overview({projId:item.tenant_id})">{{item.project}}</a></div>'
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
    networks = $http.get "#{serverURL}/networks"
    subnets = $http.get "#{serverURL}/subnets"
    projects = $http.get "#{serverURL}/projectsV3"
    $q.all([networks, subnets, projects])
      .then (values) ->
        networkList = values[0].data
        subnetList = values[1].data
        projectList = values[2].data
        subnetMap = {}
        projectMap = {}
        for project in projectList.data
          projectMap[project.id] = project.name
        for subnet in subnetList
          subnetMap[subnet.id] = subnet
        for network, index in networkList
          network.SHARED = _ String(network.shared).toUpperCase()
          network.external = _ String(network['router:external']).toUpperCase()
          if projectMap[network.tenant_id]
            network.project = projectMap[network.tenant_id]
          for sub, ind in network.subnets
            networkList[index].subnets[ind] = subnetMap[sub]
        callback networkList, networkList.length
      , (err) ->
        callback []

  initialAction: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    $q = options.$q
    serverURL = $CROSS.settings.serverURL
    $scope.create = () ->
      $state.go "admin.network.create"
    $scope.create_subnet = (link, enable) ->
      if !enable
        return
      networkId = $scope.selectedItems[0].id
      $state.go "admin.network.nId.createsubnet",
      {nId: networkId}
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
                $state.go "admin.network", {}, {reload: true}
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
            $state.go "admin.network", {}, {reload: true}
          .error (err) ->
            toastr.error _("Error at delete network.")
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

    $scope.$on 'selected', (event, detail) ->
      if !$scope.items
        $scope.selectedNetworkId = detail
        return
      if $scope.items.length < 0
        $scope.selectedNetworkId = detail
        return
      for network, index in $scope.items
        if network.id == detail
          $scope.items[index].isSelected = true
        else
          $scope.items[index].isSelected = false

  itemChange: (newVal, oldVal, $scope, options) ->
    obj = options.$this
    if newVal != oldVal
      selectedItems = []
      for item in newVal
        if $scope.selectedNetworkId
          if item.id == $scope.selectedNetworkId
            item.isSelected = true
            $scope.selectedNetworkId = undefined
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
  addition: true
  columnDefs: [
    {
      field: "name"
      displayName: _("Name")
      cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="admin.network.networkId.overview({networkId:item.id})">{{item.name}}</a></div>'
    }
    {
      field: "network"
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
      field: "dhcp"
      displayName: _("Enable DHCP")
      cellTemplate: '<div class="switch-button" switch-button status="item.condition" verbose="item.ENABLE" action="addition(item.id, item.enable_dhcp)" enable="true">{{item.ENABLE}}</div>'
    }
  ]

  listData: ($scope, options, dataQueryOpts, callback) ->
    serverURL = $CROSS.settings.serverURL
    $http = options.$http
    $q = options.$q
    $state = options.$state
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
          portInterface = port.fixed_ips
          relativedDevice[port.device_id] = port
        for router in routerList
          if relativedDevice[router.id]
            port = relativedDevice[router.id]
            for sub in port.fixed_ips
              relavivedSubnet[sub.subnet_id] = router
        networkMap = {}
        for network, index in networkList
          networkMap[network.id] = network
        for subnet in subnetList
          subnet.network = networkMap[subnet.network_id]
          if subnet.network['router:external']
            subnet.external = true
          if relavivedSubnet[subnet.id]
            subnet.router = relavivedSubnet[subnet.id]
          if subnet.enable_dhcp
            subnet.dhcp = _("Enable")
            subnet.condition = 'on'
          else
            subnet.dhcp = _("Disable")
            subnet.condition = 'off'
        callback subnetList
      , (err) ->
        callback []

  initialAction: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    $q = options.$q
    serverURL = $CROSS.settings.serverURL
    $scope.create = () ->
      $state.go "admin.network.create"
    $scope.attach = () ->
      $state.go "admin.network.nId.attach",
      {nId: $scope.selectedItems[0].id}
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
        .error (err) ->
          toastr.error _("Failed to detach router.")
      $state.go 'admin.network',
      {tab: 'subnet'}, {reload: true}

    $scope.delete = () ->
      network = $scope.selectedItems[0]
      subnetUrl = "#{serverURL}/subnets/#{network.id}"
      $http.delete subnetUrl
        .success (data) ->
          toastr.success _("Success to delete subnet: ") + network.name
        .error (err) ->
          if err
            if err.type == 'SubnetInUse'
              toastr.info _("The subnet: ") + "#{network.name}" + \
              _("has been in use, can't delete.")
          else
            toastr.error _("Failed delete subnet: ") + network.name
      $state.go "admin.network", {tab: 'subnet'}, {reload: true}

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

    $scope.$on 'selected', (event, detail) ->
      if !$scope.items
        $scope.selectedNetworkId = detail
        return
      if $scope.items.length < 0
        $scope.selectedNetworkId = detail
        return
      for network, index in $scope.items
        if network.id == detail
          $scope.items[index].isSelected = true
        else
          $scope.items[index].isSelected = false

  itemChange: (newVal, oldVal, $scope, options) ->
    obj = options.$this
    if newVal != oldVal
      selectedItems = []
      for item in newVal
        if $scope.selectedNetworkId
          if item.id == $scope.selectedNetworkId
            item.isSelected = true
            $scope.selectedNetworkId = undefined
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
