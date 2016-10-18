'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.project.instance')
  .controller 'project.instance.softDeletedCtrl', ($scope, $http,
  $window, $q, $state, $interval, $templateCache, $selectedItem,
  $compile, $animate, $modal, $instanceSetUp, $running) ->

    serverUrl = $window.$CROSS.settings.serverURL
    tenantId = $CROSS.person.project.id

    # Category for instance action
    $scope.singleSelectedItem = {}
    $scope.labileInstanceQueue = {}
    $scope.softDeleted = true

    $instanceSetUp $scope, $interval, $running
    # Variates for dataTable
    # --start--

    # For checkbox select
    $scope.AllSelectedItems = false
    $scope.NoSelectedItems = true

    # For tabler footer and pagination or filter
    $scope.showFooter = true
    $scope.unFristPage = false
    $scope.unLastPage = false

    $scope.totalServerItems = 0
    $scope.pagingOptions = {
      pageSizes: [15, 25, 50]
      pageSize: 15
      currentPage: 1
    }
    $scope.filterOptions =
      filterText: '',
      useExternalFilter: true

    $scope.instances = []

    $scope.instancesOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      pageMax: 5
    }

    # Functions for handle event from action

    $scope.selectedItems = []

    # Function for async list instances
    # TODO(ZhengYue): Get left time of soft deleted server.
    $scope.getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        dataQueryOpts =
          dataFrom: parseInt(pageSize) * parseInt(currentPage)
          dataTo: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize)
          status: 'SOFT_DELETED'
          tenant_id: tenantId
        $cross.listDetailedServers $http, $window, $q, dataQueryOpts,
        (instances, total) ->
          $scope.setPagingData(instances, total)
          (callback && typeof(callback) == "function") && callback()
      , 300)

    $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    # Callback for instance list after paging change
    watchCallback = (newVal, oldVal) ->
      $scope.instancesOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage

    $scope.$watch('pagingOptions', watchCallback, true)

    # Callback after instance list change
    instanceCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for instance in newVal
          if instance.status in $scope.labileStatus\
          or instance.task_state and instance.task_state != 'null'
            $scope.getLabileData(instance.id)
          if instance.isSelected == true
            selectedItems.push instance
        $scope.selectedItems = selectedItems

    $scope.$watch('instances', instanceCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    # Delete selected servers
    $scope.deleteServer = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        instanceId = item.id
        $cross.serverDelete $http, $window, instanceId, 'force', (response) ->
          # TODO(ZhengYue): Add some tips for success or failed
          if response == 200
            # TODO(ZhengYue): Unify the tips for actions
            $scope.getLabileData(instanceId)

    $scope.restoreServer = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        instanceId = item.id
        $cross.instanceAction 'restore', $http, $window,
        {'instanceId': instanceId}, (response) ->
          if response
            if response == 200
              toastr.success _("Successfully to restore instance:" + item.name)
              $state.go 'project.instance', {tab: 'soft-deleted'}
              $scope.getLabileData(instanceId)
            else
              toastr.error _("Failed to restore instance:" + item.name)
          else
            toastr.error _("Failed to restore instance:" + item.name)

    $selectedItem $scope, 'instances'
