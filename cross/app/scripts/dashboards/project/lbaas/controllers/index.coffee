'use strict'

angular.module('Cross.project.lbaas')
  .controller 'project.lbaas.LBCtr', ($scope, $http, $window,
  $q, $state, $tabs) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.slug = _ "Load Banlancer"
    $scope.tabs = [{
      title: _('Load Banlancer')
      template: 'lb.html'
      enable: true
    }]

    $tabs($scope)
    lbTable = new LBTable($scope)
    lbTable.init($scope, {
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
          verbose: _("Create Load Balancer")
          enable: true
          action: $scope.create
          link: 'project.lbaas.create'
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
          name: 'quota'
          verbose: _('VIP Manage')
          enable: false
          action: $scope.vipManage
          type: 'link'
          restrict: {
            batch: false
          }
        }
        {
          name: 'member'
          verbose: _('Member Manage')
          enable: false
          action: $scope.memberManage
          type: 'link'
          restrict: {
            batch: false
          }
        }
      ]
    }

class LBTable extends $cross.TableView
  labileStatus: []
  slug: 'lbs'
  columnDefs: [
    {
      field: "name"
      displayName: _("Name")
      cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="project.lbaas.lbId.overview({lbId:item.id})">{{item.name}}</a></div>'
    }
    {
      field: "subnet"
      displayName: _("Subnet")
      cellTemplate: '<div class=ngCellText>{{item.subnet.name}}:{{item.subnet.cidr}}</div>'
    }
    {
      field: "provider"
      displayName: _("Provider")
      cellTemplate: '<div class=ngCellText>{{item.provider}}</div>'
    }
    {
      field: "protocol"
      displayName: _("Protocol")
      cellTemplate: '<div class="ngCellText">{{item.protocol}}</div>'
    }
    {
      field: "vip.name"
      displayName: _("Vip")
      cellTemplate: '<div class=ngCellText>{{item.vip.address}}</div>'
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
    pools = $http.get "#{serverURL}/lb/pools?tenant_id=#{tenantId}"
    vips = $http.get "#{serverURL}/lb/vips"
    subnets = $http.get "#{serverURL}/subnets?tenant_id=#{tenantId}"
    $q.all([pools, vips, subnets])
      .then (values) ->
        poolList = values[0].data
        vipList = values[1].data
        subnetList = values[2].data
        # Prepare relatived resource
        vipMap = {}
        subnetMap = {}
        for vip in vipList
          vipMap[vip.id] = vip
        for subnet in subnetList
          subnetMap[subnet.id] = subnet
        for pool in poolList
          if vipMap[pool.vip_id]
            pool.vip = vipMap[pool.vip_id]
          if subnetMap[pool.subnet_id]
            pool.subnet = subnetMap[pool.subnet_id]
        callback poolList, poolList.length
      , (error) ->
        callback []

  initialAction: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    $q = options.$q
    serverURL = $CROSS.settings.serverURL
    $scope.create = () ->
      $state.go "project.lbaas.create"
    $scope.vipManage = () ->
      if $scope.selectedItems.length == 1
        $state.go 'project.lbaas.LBId.vip', {LBId: $scope.selectedItems[0].id}
      else
        return
    $scope.memberManage = () ->
      if $scope.selectedItems.length == 1
        $state.go 'project.lbaas.LBId.member', {LBId: $scope.selectedItems[0].id}
      else
        return

    $scope.delete = () ->
      # Check vip is linked to current pool,
      # if yes, delete the vip first, then delete pool
      deletePool = (poolId, poolName) ->
        $http.delete "#{serverURL}/lb/pools/#{poolId}"
          .success (data) ->
            toastr.success _("Success to delete load balancer:") + poolName
            $state.go "project.lbaas", {}, {reload: true}
          .error (err) ->
            toastr.error _("Failed to delete load balancer.")
      pool = $scope.selectedItems[0]
      if pool.vip_id
        vipUrl = "#{serverURL}/lb/vips/#{pool.vip_id}"
        $http.delete(vipUrl)
          .success (data) ->
            deletePool pool.id, pool.name
          .error (err) ->
            toastr.error _("Failed to delete load balancer.")
      else
        deletePool pool.id, pool.name
      # TODO(ZhengYue): Delete the health monitor
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

      for action in $scope.actionButtons.buttonGroup
        if !action.restrict
          continue
        obj.judgeAction(action, selectedItems)

  judgeAction: (action, selectedItems) ->
    # TODO(ZhengYue): Rewrite this function
    restrict = {
      batch: true
    }
    for key, value of action.restrict
      restrict[key] = value

    if selectedItems.length == 0
      action.enable = false
      return
    else if selectedItems.length == 1
      action.enable = true
    else if selectedItems.length > 0
      if action.restrict.batch
        action.enable = true
      else
        action.enable = false
