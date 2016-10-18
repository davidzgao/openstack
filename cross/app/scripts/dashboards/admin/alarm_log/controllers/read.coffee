'use strict'

angular.module('Cross.admin.alarm_log')
  .controller 'admin.alarm_log.ReadLogCtr', ($scope, $http, $window,
  $q, $state, $interval) ->

    $scope.pagingOptions = {
      pageSizes: [15, 25, 50]
      pageSize: 15
      currentPage: 1
    }

    $scope.logs = []

    $scope.logsOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: false
      columnDefs: $scope.columnDefs
      pageMax: 5
      sort: $scope.sort
      addition:
        jump: $scope.jump
    }

    $scope.setPagingData = (pagedData, total) ->
      $scope.logs = pagedData
      $scope.totalServerItems = total
      $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
      $scope.logsOpts.data = $scope.logs
      $scope.logsOpts.pageCounts = $scope.pageCounts

      if !$scope.$$phase
        $scope.$apply()

    $scope.getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        dataQueryOpts =
          skip: currentPage * pageSize
          limit: pageSize
          is_read: 1

        $cross.listAlarmLog $http, $window, $q, dataQueryOpts,
        (logs, total) ->
          $scope.setPagingData(logs, total)
          # The follows is used to forbid jump to instance
          # when name is null
          # FIXME(Chen Fei): This way is need improve,
          # go to listAlarmLog to modify
          for log in logs
            if log.resource_name
              log.noClick = 'enableClick'
          (callback && typeof(callback) == "function") && callback()
      , 300)

    $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    watchCallback = (newVal, oldVal) ->
      $scope.logsOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage
    $scope.$watch('pagingOptions', watchCallback, true)

    logCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for log in newVal
          if log.resource_name
            log.resource_name = log.resource_name
          else
            log.resource_name = _('Not Exist')
          if log.isSelected == true
            selectedItems.push log

        $scope.selectedItems = selectedItems

    $scope.$watch('logs', logCallback, true)
    $scope.$watch('selectedItems', $scope.selectChange, true)

    $scope.refresResource = (resource) ->
      $scope.logsOpts.data = null
      $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                               $scope.pagingOptions.currentPage)
