'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.admin.public_network')
  .controller 'admin.public_network.PublicNetworkCtr', ($scope, $http, $window, $q,
                                         $state, $interval, $templateCache,
                                         $compile, $animate) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.note =
      title: _("Floating IP pool")
      buttonGroup:
        create: _("Create")
        delete: _("Delete")
        refresh: _("Refresh")

    # Category for instance action
    $scope.batchActionEnableClass = 'btn-disable'

    # For sort at table header
    $scope.sort = {
      reverse: false
    }

    # For tabler footer and pagination or filter
    $scope.showFooter = false
    $scope.pagingOptions =
      showFooter: $scope.showFooter

    $scope.abnormalStatus = [
      'error'
    ]

    $scope.columnDefs = [
      {
        field: "name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText" data-toggle="tooltip" data-placement="top" title="{{item.name}}" ng-bind="item.name"></div>'
      }
      {
        field: "interface"
        displayName: _("Interface")
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]" data-toggle="tooltip" data-placement="top" title="{{item.interface}}"></div>'
      }
      {
        field: "cidr"
        displayName: _("CIDR")
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]" data-toggle="tooltip" data-placement="top" title="{{item.cidr}}"></div>'
      }
      {
        field: "used"
        displayName: _("Allocated")
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
      {
        field: "total"
        displayName: _("Total")
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
    ]
    # --End--
    # Category for instance action
    $scope.singleSelectedItem = {}

    # Variates for dataTable
    # --start--

    # For checkbox select
    $scope.AllSelectedItems = false
    $scope.NoSelectedItems = true

    $scope.filterOptions =
      filterText: '',
      useExternalFilter: true

    $scope.publicNetworks = []

    $scope.publicNetworksOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      pageMax: 5
    }

    # Function for get paded instances and assign class for
    # element by status
    setPagingData = (pagedData) ->
      $scope.publicNetworks = pagedData
      # Compute the total pages
      $scope.publicNetworksOpts.data = $scope.publicNetworks

    # --End--

    # Functions for handle event from action

    $scope.selectedItems = []
    # TODO(ZhengYue): Add batch action enable/disable judge by status
    $scope.selectChange = () ->
      if $scope.selectedItems.length == 1
        $scope.NoSelectedItems = false
        $scope.batchActionEnableClass = 'btn-enable'
      else if $scope.selectedItems.length > 1
        $scope.NoSelectedItems = false
        $scope.batchActionEnableClass = 'btn-enable'
      else
        $scope.NoSelectedItems = true
        $scope.batchActionEnableClass = 'btn-disable'
        $scope.singleSelectedItem = {}

    # Functions about interaction with net
    # --Start--

    listDetailedNets = ($http, $window, $q, callback) ->
      $http.get("#{serverUrl}/os-floating-ips-bulk").success (ips) ->
        pools = {}
        for ip in ips
          pool = ip.pool
          if not pools[pool]
            pools[pool] =
              interface: ip.interface
              total: 0
              used: 0
              upper: 1
              counter: 0
              range: [255, 255, 255, 255]
          pools[pool].total += 1
          if pools[pool].total >= pools[pool].upper
            pools[pool].counter += 1
            pools[pool].upper = pools[pool].upper * 2
          if ip.project_id
            pools[pool].used += 1
          addr = ip.address.split('.')
          pools[pool].range[0] = pools[pool].range[0] & addr[0]
          pools[pool].range[1] = pools[pool].range[1] & addr[1]
          pools[pool].range[2] = pools[pool].range[2] & addr[2]
          pools[pool].range[3] = pools[pool].range[3] & addr[3]

        floatingIPPools = []
        for pool of pools
          num = 32 - pools[pool].counter
          cidr = pools[pool].range.join('.')
          if num < 31
            cidr += "/#{num}"
          item =
            name: pool
            interface: pools[pool].interface
            total: pools[pool].total
            used: pools[pool].used
            cidr: cidr
          floatingIPPools.push item

        callback floatingIPPools
      .error (err) ->
        callback []

    # Function for async list instances
    getPagedDataAsync = (callback) ->
      listDetailedNets $http, $window, $q, (pools) ->
        setPagingData(pools)
        (callback && typeof(callback) == "function") && callback()

    getPagedDataAsync()

    # Callback after instance list change
    netCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for net in newVal
          if net.isSelected == true
            selectedItems.push net
        $scope.selectedItems = selectedItems

    $scope.$watch('publicNetworks', netCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    netDelete = ($http, $window, range, callback) ->
      data = {'ip_range': range}
      $http.put("#{serverUrl}/os-floating-ips-bulk/delete", data)
        .success (rs) ->
          callback(200)
        .error (err) ->
          callback(err.status)

    # Reallocate selected servers
    $scope.deleteNet = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        range = item.cidr
        name = item.name || netId
        netDelete $http, $window, range, (response) ->
          # TODO(ZhengYue): Add some tips for success or failed
          if response == 200
            toastr.success(_('Successfully delete floating ip pool: ') + name)
            $state.go 'admin.public_network', {}, {reload: true}

    # TODO(ZhengYue): Add loading status
    $scope.refresResource = (resource) ->
      $scope.publicNetworksOpts.data = null
      getPagedDataAsync()
