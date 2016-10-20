'use strict'

###*
 # @ngdoc function
 # @name Unicorn.dashboard.instance:LogCtr
 # @description
 # # LogCtr
 # Controller of the Unicorn
###
angular.module("Unicorn.dashboard.log")
  .controller "dashboard.log.LogCtr", ($scope, $http, $q, $window,
                                      $state, $stateParams) ->
    # Initial note.
    $scope.note =
      buttonGroup:
        refresh: _("Refresh")

    $scope.note =
      query: _('Query')

    (new tableView()).init($scope, {
      $http: $http
      $q: $q
      $window: $window
      $state: $state
      $stateParams: $stateParams
    })

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
    $scope.getQuery = () ->
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

class tableView extends $unicorn.TableView
  slug: 'log'
  showCheckbox: false
  pagingOptions:
    showFooter: false
  paging: false
  columnDefs: [
      {
        field: "generated",
        displayName: _("Creat at"),
        cellTemplate: '<div class="ngCellText" data-toggle="tooltip" data-placement="top">{{item.generated|dateLocalize|date: "yyyy-MM-dd HH:mm:ss"}}</div>'
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

  listData: ($scope, options, dataQueryOpts, callback) ->
    serverUrl = $UNICORN.settings.serverURL
    $http = options.$http
    $q = options.$q
    query = $scope.getQuery()
    param = "?q.field=start_timestamp&q.value=#{query[0]}"
    param += "&q.field=end_timestamp&q.value=#{query[1]}"
    $http.get("#{serverUrl}/events#{param}").success (logs) ->
      if not logs
        # TODO:(lixipeng) messages empty handle.
        return
      $scope.query.year = $scope.query.year
      $scope.query.month = $scope.query.month
      logs = $unicorn.message.parseMessage logs
      $unicorn.message.addUserName logs, $http, $q, serverUrl, (messages) ->
        callback(tableView.setPagingData messages)
    return true

  @setPagingData: (pagedData) ->
    for log in pagedData
      if log.resource_type == 'instance'
        log.href = "#/dashboard/instance/#{log.traits.resource_id}/overview"
      if log.resource_type == 'volume_snapshot'
        log.href = "#/dashboard/volume"
      if log.resource_type == 'volume'
        log.href = "#/dashboard/volume/#{log.traits.resource_id}/overview"
      if log.resource_type == 'image'
        log.href = "#/dashboard/image/#{log.traits.resource_id}"
      if log.resource_type == 'floating_ip'
        log.href = "#/dashboard/floatingIp"
    return pagedData

  initialAction: ($scope, options) ->
    obj = options.$this
    tableOpts = "#{obj.slug}Opts"
    $scope.queryLogs = () ->
      $scope[tableOpts].data = null
      $unicorn.TableView.getPagedDataAsync $scope.pagingOptions.pageSize,
      $scope.pagingOptions.currentPage, $scope, options
