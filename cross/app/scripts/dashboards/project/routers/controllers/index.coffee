'use strict'

angular.module('Cross.project.routers')
  .controller 'project.routers.RouterCtr', ($scope, $http, $window,
  $q, $state, $tabs) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.slug = _ "Routers"
    $scope.tabs = [{
      title: _('Routers')
      template: 'router.html'
      enable: true
    }]

    $tabs($scope)
    routerTable = new RouterTable($scope)
    routerTable.init($scope, {
      $http: $http
      $window: $window
      $q: $q
      $state: $state
    })

    $scope.actionButtons = {
      hasMore: true
      fresh: $scope.fresh
      buttons: [
        {
          type: 'single'
          tag: 'a'
          name: 'create'
          verbose: _("Create Router")
          enable: true
          action: $scope.create
          link: 'project.routers.create'
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
      buttonGroup: [
        {
          name: 'open_gateway'
          verbose: _("Open Gateway")
          enable: false
          type: 'link'
          action: $scope.openGateway
          link: 'project.routers.rId.open'
          restrict: {
            batch: false
            field: 'gateway'
            conditon: 'not'
          }
        }
        {
          name: 'clear_gateway'
          verbose: _("Close Gateway")
          enable: false
          action: $scope.clearGateway
          type: 'action'
          confirm: _ "Close"
          restrict: {
            batch: false
            field: 'gateway'
            condition: 'yes'
          }
        }
        {
          name: 'add_interface'
          verbose: _("Add Interface")
          enable: false
          action: $scope.openGateway
          type: 'link'
          confirm: _ "Add"
          link: 'project.routers.rId.add_port'
          restrict: {
            batch: false
          }
        }
      ]
    }

class RouterTable extends $cross.TableView
  labileStatus: []
  slug: 'routers'
  columnDefs: [
    {
      field: "name"
      displayName: _("Name")
      cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="project.routers.routerId.overview({routerId:item.id})">{{item.name}}</a></div>'
    }
    {
      field: "status"
      displayName: _("Status")
      cellTemplate: '<div class="ngCellText status" ng-class="item.status"><i></i>{{item.STATUS}}</div>'
    }
    {
      field: "floating"
      displayName: _("FloatingIP")
      cellTemplate: '<div class=ngCellText ng-class="open"><li ng-repeat="ip in item.floating">{{ip}}</li><li ng-if="item.floating.length==0">{{"" | parseNull}}</li>v class="more-in-cell" title={{showAll}} ng-if="item.floating.length>1" ng-click="cellOpen($event.currentTarget)"></div></div>'
    }
    {
      field: "gateway_name"
      displayName: _("Gateway")
      cellTemplate: '<div class="ngCellText">{{item.gateway.name}}</div>'
    }
  ]

  listData: ($scope, options, dataQueryOpts, callback) ->
    serverURL = $CROSS.settings.serverURL
    $http = options.$http
    $q = options.$q
    tenantId = $CROSS.person.project.id
    routers = $http.get "#{serverURL}/routers?tenant_id=#{tenantId}"
    networks = $http.get "#{serverURL}/networks"
    ports = $http.get "#{serverURL}/ports?tenant_id=#{tenantId}"
    $q.all([routers, networks, ports])
      .then (values) ->
        routerList = values[0]
        networkList = values[1]
        portList = values[2]
        networkMap = {}
        portMap = {}
        for network in networkList.data
          networkMap[network.id] = network
        for port in portList.data
          portMap[port.device_id] = port
        for router in routerList.data
          router.floating = []
          if router.external_gateway_info
            gateway = router.external_gateway_info
          else
            continue
          for ip in gateway.external_fixed_ips
            router.floating.push ip.ip_address
          router.gateway = networkMap[router.external_gateway_info.network_id]
          router.gateway_name = router.gateway.name
          if portMap[router.id]
            router.ports = true
        callback routerList.data

  initialAction: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    $q = options.$q
    serverURL = $CROSS.settings.serverURL
    $scope.create = () ->
      $state.go "project.routers.create"
    $scope.delete = () ->
      deleteRouter = (routerId, routerName) ->
        $http.delete "#{serverURL}/routers/#{routerId}"
          .success (data) ->
            toastr.success _("Success to delete router:") + routerName
            $state.go "project.routers", {}, {reload: true}
      subnetUrl = "#{serverURL}/ports?device_id="
      router = $scope.selectedItems[0]
      $http.get(subnetUrl + router.id)
        .success (data) ->
          if data.length == 1
            if data[0].device_owner == 'network:router_gateway'
              deleteRouter(router.id, router.name)
          else if data.length > 1
            toastr.info _("This router has connected to subnet, separate subnet before delete it.")
          else
            deleteRouter(router.id, router.name)
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
        if $scope.selectedItemId
          if item.id == $scope.selectedItemId
            item.isSelected = true
            $scope.selectedItemId = undefined
        if item.isSelected == true
          selectedItems.push item
      $scope.selectedItems = selectedItems

      for action in $scope.actionButtons.buttons
        if !action.restrict
          continue
        obj.judgeAction(action, selectedItems)

      for action in $scope.actionButtons.buttonGroup
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
