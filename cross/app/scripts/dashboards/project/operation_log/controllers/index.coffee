'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.project.operation_log')
  .controller 'project.operation_log.OperationLogCtr', ($scope, $http, $window, $q,
                              $state, $interval, $templateCache,
                              $compile, $animate) ->

    serverUrl = $window.$CROSS.settings.serverURL

    $scope.slug = _ 'Operation logs'

    # Tabs at instance page
    $scope.tab =
      title: _('Operation logs')

    $scope.buttonGroup =
      refresh: _("Refresh")

    $scope.note =
      query: _('Query')

    # Variates for dataTable
    # --start--

    # For sort at table header
    $scope.sort = {
      reverse: false
    }

    # Variate used for statistic query
    $scope.query = {}
    monthNames = [ _("January"), _("February"), _("March"),
                   _("April"), _("May"), _("June"), _("July"),
                   _("August"), _("September"), _("October"),
                   _("November"), _("December")]
    getDateList = () ->
      # Get latest 4 years and sort month by current month at first
      date = new Date()
      yearList = []
      currentYear = date.getFullYear()
      currentMonth = date.getMonth()
      $scope.currentYear = currentYear
      $scope.currentMonth = currentMonth
      months = []
      for month, index in monthNames
        months.push {index: index, name: month}
      $scope.monthNames = months
      yearList.push currentYear
      yearList.push currentYear - 1
      yearList.push currentYear - 2
      yearList.push currentYear - 3
      $scope.yearList = yearList

    getDateList()
    $scope.query.year = $scope.currentYear
    $scope.query.month = $scope.monthNames[$scope.currentMonth].index
    getQuery = () ->
      # Get start and end for statistic query
      month = $scope.query.month
      if typeof($scope.query.month) == 'string'
        month = parseInt($scope.query.month)
      year = $scope.query.year
      if typeof(year) == 'string'
        year = $scope.yearList[parseInt(year)]
      firstDay = new Date(year, month, 1)
      firstDay.setUTCHours(24)
      firstDay = firstDay.toISOString()
      firstDay = firstDay.substr(0, 23)
      lastDay = new Date(year, month + 1, 0)
      lastDay.setUTCHours(24)
      lastDay = lastDay.toISOString()
      lastDay = lastDay.substr(0, 23)
      $scope.queryDate = "#{year} #{$scope.monthNames[month].name}"
      if month == $scope.currentMonth and year == $scope.currentYear
        lastDay = new Date().toISOString()
        lastDay = lastDay.substr(0, 23)

      return [firstDay, lastDay]

    # For tabler footer and pagination or filter
    $scope.showFooter = false
    $scope.unFristPage = false
    $scope.unLastPage = false

    $scope.columnDefs = [
      {
        field: "generated",
        displayName: _("Creat at"),
        cellTemplate: '<div class="ngCellText" data-toggle="tooltip" data-placement="top">{{item.generated|dateLocalize | date:"yyyy-MM-dd HH:mm"}}</div>'
      }
      {
        field: "resource_name",
        displayName: _("Resource name"),
        cellTemplate: '<div title="{{item.traits.resource_name}}"><a href="{{item.href}}">{{item.traits.resource_name}}</a></div>'
      }
      {
        field: "action",
        displayName: _("Action"),
        cellTemplate: '<div class="ngCellText" ng-bind="item.action_msg" data-toggle="tooltip" data-placement="top"></div>'
      }
      {
        field: "user_name",
        displayName: _("Operator"),
        cellTemplate: '<div class="ngCellText" ng-bind="item.user_name" data-toggle="tooltip" data-placement="top"></div>'
      }
      {
        field: "status",
        displayName: _("Status"),
        cellTemplate: '<div class="ngCellText {{item.state===\'success\'?\'active\':\'error\'}} status" data-toggle="tooltip" data-placement="top"><i></i>{{item.state|i18n}}</div>'
      }
    ]
    # --End--

    # Category for instance action
    $scope.singleSelectedItem = {}

    # For checkbox select
    $scope.AllSelectedItems = false
    $scope.NoSelectedItems = true

    $scope.totalServerItems = 0
    $scope.pagingOptions =
      showFooter: $scope.showFooter
    $scope.filterOptions =
      filterText: '',
      useExternalFilter: true

    $scope.logs = [
    ]

    $scope.logsOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: false
      columnDefs: $scope.columnDefs
      pageMax: 5
    }

    # Function for get paded instances and assign class for
    # element by status
    setPagingData = (pagedData) ->
      for log in pagedData
        if log.resource_type == 'instance'
          log.href = "#/project/instance/#{log.traits.resource_id}/overview"
        if log.resource_type == 'volume_snapshot'
          log.href = "#/project/volume?tab=backup"
        if log.resource_type == 'volume'
          log.href = "#/project/volume/#{log.traits.resource_id}/overview"
        if log.resource_type == 'image'
          log.href = "#/project/image/#{log.traits.resource_id}"
        if log.resource_type == 'floating_ip'
          log.href = "#/project/public_net"
      $scope.logs = pagedData
      $scope.logsOpts.data = $scope.logs
      $scope.logsOpts.pageCounts = $scope.pageCounts

      if !$scope.$$phase
        $scope.$apply()

    # --End--

    # Functions for handle event from action

    $scope.selectedItems = []
    # TODO(ZhengYue): Add batch action enable/disable judge by status
    $scope.selectChange = () ->
      return

    # Functions about interaction with server
    # --Start--

    listDetailedServers = ($http, $window, $q, dataQueryOpts, callback) ->
      query = getQuery()
      param = "?q.field=start_timestamp&q.value=#{query[0]}"
      param += "&q.field=end_timestamp&q.value=#{query[1]}"
      $http.get("#{serverUrl}/events#{param}").success (logs) ->
        if not logs
          # TODO:(lixipeng) messages empty handle.
          return
        $scope.query.year = dataQueryOpts.year
        $scope.query.month = dataQueryOpts.month
        logs = $cross.message.parseMessage logs
        $cross.message.addUserName logs, $http, $q, serverUrl, (messages) ->
          callback messages

    # Function for async list instances
    getPagedDataAsync = (callback) ->
      dataQueryOpts =
        year: $scope.query.year
        month: $scope.query.month
      listDetailedServers $http, $window, $q, dataQueryOpts,
      (logs) ->
        setPagingData(logs)
        (callback && typeof(callback) == "function") && callback()

    getPagedDataAsync()

    $scope.queryLogs = () ->
      $scope.logsOpts.data = null
      getPagedDataAsync()
