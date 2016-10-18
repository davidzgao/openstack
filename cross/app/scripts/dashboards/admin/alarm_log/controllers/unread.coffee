'use strict'

angular.module('Cross.admin.alarm_log')
  .controller 'admin.alarm_log.UnreadLogCtr', ($scope, $http, $window,
  $q, $state, $interval) ->

    $scope.selectedItems = []
    $scope.readEnableClass = 'btn-disable'

    $scope.selectChange = () ->
      if $scope.selectedItems.length >= 1
        $scope.readEnableClass = 'btn-enable'
      else
        $scope.readEnableClass = 'btn-disable'

    $scope.pagingOptions = {
      pageSizes: [15, 25, 50]
      pageSize: 15
      currentPage: 1
    }

    $scope.logs = []

    $scope.logsOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
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
          is_read: 0

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
          if log.isSelected == true
            selectedItems.push log
          if log.resource_name
            log.resource_name = log.resource_name
          else
            log.resource_name = _('Not Exist')
          if log.alarm_enable == 'enable'
            log.alarm_enable = 'enableClick'

        $scope.selectedItems = selectedItems

    $scope.$watch('logs', logCallback, true)
    $scope.$watch('selectedItems', $scope.selectChange, true)

    $scope.readTips = _("Are you sure mark selected log as read?")

    $scope.readLog = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        logId = item.history_id
        $cross.readAlarmLog $http, $window, logId, () ->
          toastr.success _("Success mark alarm log as read!")
          $state.go "admin.alarm_log", {}, {reload: true}

    $scope.refresResource = (resource) ->
      $scope.logsOpts.data = null
      $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                               $scope.pagingOptions.currentPage)
