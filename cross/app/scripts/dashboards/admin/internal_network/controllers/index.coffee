'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.admin.internal_network')
  .controller 'admin.internal_network.InternalNetworkCtr', ($scope, $http, $window, $q,
                                         $state, $interval, $templateCache,
                                         $compile, $animate) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.note =
      title: _("Internal network")
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
        cellTemplate: '<div class="ngCellText" data-toggle="tooltip" data-placement="top" title="{{item.label}}" ng-bind="item.label"></div>'
      }
      {
        field: "cidr"
        displayName: _("CIDR")
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]" data-toggle="tooltip" data-placement="top" title="{{item.cidr}}"></div>'
      }
      {
        field: "gateway"
        displayName: _("Gateway")
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]" data-toggle="tooltip" data-placement="top" title="{{item.gateway}}"></div>'
      }
      {
        field: "bridge"
        displayName: _("Bridge")
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]" data-toggle="tooltip" data-placement="top" title="{{item.bridge}}"></div>'
      }
      {
        field: "created_at"
        displayName: _("Created At")
        cellTemplate: '<div>{{item[col.field]|dateLocalize|date: "yyyy-MM-dd HH:mm"}}</div>'
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

    $scope.internalNetworks = []

    $scope.internalNetworksOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
    }

    # Function for get paded instances and assign class for
    # element by status
    setPagingData = (pagedData) ->
      $scope.internalNetworks = pagedData
      # Compute the total pages
      $scope.internalNetworksOpts.data = $scope.internalNetworks

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
      $http.get("#{serverUrl}/os-networks").success (nets) ->
        callback nets
      .error (err) ->
        callback []

    # Function for async list instances
    getPagedDataAsync = (callback) ->
      currentPage = currentPage - 1
      listDetailedNets $http, $window, $q, (nets, total) ->
        setPagingData(nets, total)
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

    $scope.$watch('internalNetworks', netCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    netDelete = ($http, $window, netId, callback) ->
      $http.delete("#{serverUrl}/os-networks/#{netId}")
        .success (rs) ->
          callback(200)
        .error (err) ->
          callback(err.status)

    # Reallocate selected servers
    $scope.deleteNet = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        netId = item.id
        name = item.label || netId
        if item.project_id
          param = {
            disassociate_project: null
          }
          $http.post("#{serverUrl}/os-networks/#{netId}/action", param)
            .success (res) ->
              netDelete $http, $window, netId, (response) ->
                # TODO(ZhengYue): Add some tips for success or failed
                if response == 200
                  toastr.success(_('Successfully delete network: ') + name)
                  $state.go 'admin.internal_network', {}, {reload: true}
                if response == 500
                  msg = _("Failed to delete network: ")
                  msg += name + _(", please confirm whether this network is used")
                  toastr.error msg
            .error (err) ->
              msg = _("Failed to delete network")
              toastr.error msg
        else
          netDelete $http, $window, netId, (response) ->
            # TODO(ZhengYue): Add some tips for success or failed
            if response == 200
              toastr.success(_('Successfully delete network: ') + name)
              $state.go 'admin.internal_network', {}, {reload: true}
            if response == 500
              msg = _("Failed to delete network: ")
              msg += name + _(", please confirm whether this network is used")
              toastr.error msg

    $scope.refresResource = (resource) ->
      $scope.internalNetworksOpts.data = null
      getPagedDataAsync()
