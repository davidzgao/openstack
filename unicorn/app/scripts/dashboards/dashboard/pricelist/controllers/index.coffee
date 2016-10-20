'use strict'

###*
 # @ngdoc function
 # @name Unicorn.dashboard.instance:PricelistCtr
 # @description
 # # PricelistCtr
 # Controller of the Unicorn
###
angular.module("Unicorn.dashboard.pricelist")
  .controller "dashboard.pricelist.PricelistCtr", ($scope, $http,
  $q, $window, $state, $interval) ->
    return true
  .controller "dashboard.pricelist.instanceCtr", ($scope, $http,
  $q, $window, $state, $interval) ->

    instancePriceTable = new InstancePriceTable($scope)
    instancePriceTable.init($scope, {
      $state: $state
      $http: $http
      $window: $window
      $interval: $interval
      $q: $q
    })
    $scope.userId = $UNICORN.person.user.id
    $scope.userName = $UNICORN.person.user.username

    $scope.query={}
    monthNames = [ _("January"), _("February"), _("March"),
                   _("April"), _("May"), _("June"), _("July"),
                   _("August"), _("September"), _("October"),
                   _("November"), _("December")]

    $scope.note = {
      userName: _("userName")
      searchTime: _("searchTime")
      query: _("Query")
      export: _("Export")
      totalTime: _("totalTime")
      totalPrice: _("totalPrice")
    }

    $scope.columnDefs = [
      {
        field: "resource_name"
        displayName: _("Instance Name")
        cellTemplate: '<div class="ngCellText">{{item[col.field]}}</div>'
      }
      {
        field: "vcpus"
        displayName: _("CPU")
        cellTemplate: '<div class="ngCellText">{{item[col.field]}}</div>'
      }
      {
        field: "memory_mb"
        displayName: _("RAM (GB)")
        cellTemplate: '<div class="ngCellText">{{item[col.field] | unitSwitch}}</div>'
      }
      {
        field: "disk_gb"
        displayName: _("Disk (GB)")
        cellTemplate: '<div class="ngCellText">{{item[col.field]}}</div>'
      }
      {
        field: "run_time"
        displayName: _("Uptime (Hour)")
        cellTemplate: '<div class="ngCellText">{{item[col.field] | fixed}}</div>'
      }
      {
        field: "run_price"
        displayName: _("Price")
        cellTemplate: '<div class="ngCellText">{{item[col.field] | fixed}}</div>'
      }
    ]
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
      yearList.push (currentYear - 1)
      yearList.push (currentYear - 2)
      yearList.push (currentYear - 3)
      $scope.yearList = yearList

    getDateList()
    $scope.query.year = $scope.yearList[0]
    $scope.query.month = $scope.monthNames[$scope.currentMonth]
    $scope.getQuery = () ->
      # Get start and end for statistic query
      month = $scope.query.month.index
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

    $scope.getItemtipr = (query, events, itemprice) ->
      startAt = query[0]
      endAt = query[1]
      userTotal = {}
      userTotal['total_price'] = 0
      userTotal['total_time'] = 0
      total_time = 0
      total_price = 0
      instances = events
      price = itemprice
      for item in instances
        if item['deleted_at']
          dateDay = Date.parse(item.deleted_at)
        else
          dateDay = Date.parse(endAt)
        runTime = dateDay - Date.parse(item.generated)
        item.run_time = runTime / (3600 * 1000)
        total_time += item.run_time if item.run_time
        userTotal['total_time'] = total_time.toFixed(2)

        service_type = String(item.service)
        if service_type.match("^compute")
          item.run_price = (parseInt(item.vcpus)*price.cpu + parseInt(item.memory_mb)/1024*price.ram +
              parseInt(item.disk_gb)*price.volume)*item.run_time
          item.resource_name = item.resource_name + _('Instance')
        if service_type.match("^volume")
          item.run_price = (parseInt(item.size)*price.volume)*item.run_time
          item.resource_name = item.resource_name + _('Volume')
          item.disk_gb = item.size
        total_price += item.run_price if item.run_price
        userTotal['total_price'] = total_price.toFixed(2)
      $scope.userTotal = userTotal

    $scope.$on 'instanceData', (event, instanceData) ->
      $scope.instanceData = instanceData


class InstancePriceTable extends $unicorn.TableView
  labileStatus: [
    'creating'
    'error_deleting'
    'deleting'
    'saving'
    'queued'
    'downloading'
  ]
  slug: 'instancePrice'
  showCheckbox: false
  columnDefs: [
    {
      field: "resource_name",
      displayName: _("Name"),
      cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.resource_name}}">
                     <a ui-sref="dashboard.pricelist.instanceDetail({ service: \'{{item.service}}\',cpus:\'{{item.vcpus}}\',name:\'{{item[col.field]}}\',
                     run_time:\'{{item.run_time}}\',mem:\'{{item.memory_mb | unitSwitch}}\',disk:\'{{item.disk_gb}}\',size:\'{{item.size}}\' })"
                     ng-bind="item.resource_name"></a></div>'
    }
    {
      field: "run_time",
      displayName: _("Uptime (Hour)"),
      cellTemplate: '<div class="ngCellText">{{item.run_time | fixed}}</div>'
    }
    {
      field: "run_price"
      displayName: _("Price")
      cellTemplate: '<div class="ngCellText">{{item.run_price | fixed}}</div>'
    }
  ]
  listData: ($scope, options, dataQueryOpts, callback) ->
    serverUrl = $UNICORN.settings.serverURL
    userId = $UNICORN.person.user.id
    $http = options.$http
    $q = options.$q

    query = $scope.getQuery()
    startAt = query[0]
    endAt = query[1]

    param = "?q.field=event_type&q.op=eq&q.value=compute.instance.create.end\
             &q.field=start_timestamp&q.value=#{startAt}&q.field=end_timestamp&q.value=#{endAt}"
    paramDel = "?q.field=event_type&q.op=eq&q.value=compute.instance.delete.end\
             &q.field=start_timestamp&q.value=#{startAt}&q.field=end_timestamp&q.value=#{endAt}"
    volparam = "?q.field=event_type&q.op=eq&q.value=volume.create.end\
    &q.field=start_timestamp&q.value=#{startAt}&q.field=end_timestamp&q.value=#{endAt}"
    volparamDel = "?q.field=event_type&q.op=eq&q.value=volume.delete.end\
    &q.field=start_timestamp&q.value=#{startAt}&q.field=end_timestamp&q.value=#{endAt}"

    voleventsParam = "#{serverUrl}/events#{volparam}"
    voldeletedParam = "#{serverUrl}/events#{volparamDel}"
    eventsParam = "#{serverUrl}/events#{param}"
    deletedParam = "#{serverUrl}/events#{paramDel}"
    priceParam = "#{serverUrl}/prices"

    eventsList = $http.get eventsParam, {
      params:
        all_tenants: 1
    }
      .then (response) ->
        return response.data
    deletedList = $http.get deletedParam, {
      params:
        all_tenants: 1
    }
      .then (response) ->
        return response.data
    voleventsList = $http.get voleventsParam, {
      params:
        all_tenants: 1
    }
      .then (response) ->
        return response.data
    voldeletedList = $http.get voldeletedParam, {
      params:
        all_tenants: 1
    }
      .then (response) ->
        return response.data
    priceList = $http.get priceParam
      .then (response) ->
        return response.data

    $q.all ([eventsList, deletedList, voleventsList, voldeletedList, priceList])
      .then (values) ->
        if values[0] and values[2]
          data = values[0]
          deldata = values[1]
          voldata = values[2]
          delvoldata = values[3]
          pricedata = values[4]
          events = []
          deleted = []
          prices = []

          for event, index in deldata
            dictTrait = {}
            for trait in event.traits
              dictTrait[trait.name] = trait.value
            if dictTrait['resource_id']
              if not deleted[dictTrait['resource_id']]
                deleted[dictTrait['resource_id']] = []
              deleted[dictTrait['resource_id']].push dictTrait

          for event, index in data
            dictTrait = {}
            for trait in event.traits
              dictTrait[trait.name] = trait.value
            dictTrait['generated'] = event.generated
            if deleted[dictTrait['resource_id']]
              dictTrait['deleted_at'] = deleted[dictTrait['resource_id']][0].deleted_at
            if dictTrait['user_id'] == userId
              events.push dictTrait

          for event, index in delvoldata
            dictTrait = {}
            for trait in event.traits
              dictTrait[trait.name] = trait.value
            if dictTrait['resource_id']
              if not deleted[dictTrait['resource_id']]
                deleted[dictTrait['resource_id']] = []
              deleted[dictTrait['resource_id']].push dictTrait

          for event, index in voldata
            dictTrait = {}
            for trait in event.traits
              dictTrait[trait.name] = trait.value
            dictTrait['generated'] = event.generated
            if deleted[dictTrait['resource_id']]
              dictTrait['deleted_at'] = deleted[dictTrait['resource_id']][0].deleted_at
            if dictTrait['user_id'] == userId
              events.push dictTrait

          for event, index in pricedata
            prices[event.name] = event.price

          if data and voldata
            $scope.getItemtipr(query,events,prices)
            $scope.$emit('instanceData',events)
            callback events
          else
            $scope.eventsDict = []
        else
          toastr.error _("Failed to a get usage.")

  initialAction: ($scope, options) ->
    super $scope, options
    userId = $UNICORN.person.user.id
    userName = $UNICORN.person.user.username
    obj = options.$this
    $http = options.$http
    $window = options.$window
    $state = options.$state
    tableOpts = "#{obj.slug}Opts"

    $scope.itemSearch = () ->
      $scope.fresh()

    $scope.itemExport = () ->
      argId = "user_#{userId}_statistic"
      exp = new Blob([document.getElementById(argId).innerHTML],
      {
        type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=utf-8"
      })
      saveAs(exp, "Report_#{userName}.xls")
