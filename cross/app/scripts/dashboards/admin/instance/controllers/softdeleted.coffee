'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.admin.instance')
  .controller 'admin.instance.softDeletedCtrl', ($scope, $http,
  $state, $interval, $instanceSetUp, $gossipService, $window, $q,
  $running, $deleted, $selectedItem) ->
    $scope.$on '$gossipService.instance', (event, meta) ->
      id = meta.payload.id
      $cross.serverGet $http, $window, $q, id, (instance) ->
        if $scope.instances
          counter = 0
          len = $scope.instances.length
          loop
            break if counter >= len
            if $scope.instances[counter].id == id
              break
            counter += 1
          if not instance
            $scope.instances.splice counter, 1
            return
          if $scope.judgeStatus
            $scope.judgeStatus instance
            $scope.instances[counter] = instance

    # Category for instance action
    $scope.singleSelectedItem = {}
    $scope.labileInstanceQueue = {}
    $scope.softDeleted = true

    $instanceSetUp $scope, $interval, $running

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
      slug: _ "Instances"
    }

    $scope.selectedItems = []

    # Function for async list instances
    # TODO(ZhengYue): Get left time of soft deleted server.
    $scope.getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        dataQueryOpts =
          dataFrom: parseInt(pageSize) * parseInt(currentPage)
          dataTo: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize)
          search: true
          searchKey: 'status'
          all_tenants: true
          searchValue: 'SOFT_DELETED'
          require_detail: true
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
        message =
          object: "instance-#{instanceId}"
          priority: 'info'
          loading: 'true'
          content: _(["Instance %s is %s ...", item.name, _("deleting")])
        $gossipService.receiveMessage message
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
              $scope.getLabileData(instanceId)
            else
              toastr.error _("Failed to restore instance:" + item.name)
          else
            toastr.error _("Failed to restore instance:" + item.name)

    $selectedItem $scope, 'instances'
