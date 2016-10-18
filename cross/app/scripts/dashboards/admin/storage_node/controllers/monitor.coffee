'use strict'

angular.module 'Cross.admin.storage_node'
  .controller 'admin.storage_node.StorageMonitorCtr', ($scope, $http,
  $window, $q, $interval, $state) ->
    $scope.monitorTabs = [{
        title: _('Real Time')
        enable: true
        template: 'real-time-monitor'
      },
      {
        title: _('Latest hour')
        enable: true
        template: 'one-hour-ago'
      },
      {
        title: _('Latest day')
        enable: true
        template: 'one-day-ago'
      },
      {
        title: _('Latest week')
        enable: true
        template: 'one-week-ago'
      }
      {
        title: _('Latest month')
        enable: true
        template: 'one-month-ago'
      }
    ]

    $scope.currentMonitorTab = 'real-time-monitor'

    $scope.switchTab = (tab) ->
      $scope.currentMonitorTab = tab.template
      if $.intervalList
        angular.forEach $.intervalList, (task, index) ->
          clearInterval task

    $scope.isActiveTab = (tabUrl) ->
      return tabUrl == $scope.currentMonitorTab

angular.module('Cross.admin.storage_node')
  .controller 'admin.storage_node.StorageMonitorRealTimeCtl', ($scope,
  $http,$window, $q, $stateParams, $state, $gossip) ->
    _DEFAULT_SET_LENGTH = 12

    query = {
      limit: _DEFAULT_SET_LENGTH
    }
    meterURL = $window.$CROSS.settings.serverURL + '/meters/'

    getHistoryQueryParam = () ->
      _current_tab = $scope.currentMonitorTab
      parts = _current_tab.split('-')
      return parts[1]

    $scope.queryGist = getHistoryQueryParam()
    if $scope.queryGist == 'time'
      $scope.realTime = true
    else
      $scope.realTime = false

    if $scope.realTime
      $scope.$on '$destroy', ()->
        $gossip.destroyRealtime 'ceph'
      $gossip.startRealtime 'ceph'

    getURL = (options) ->
      q = options.q
      baseURL = options.baseURL
      queryParams = options.baseURL
      if $scope.queryGist == 'time'
        if options.limit
          limit = options.limit
          queryParams = "?limit=#{limit}"
        else
          queryParams = "?"
        if options.item
          item = options.item
          url = "#{baseURL}#{item}#{queryParams}"
        else
          url = "#{baseURL}#{queryParams}"
        return url
      else
        queryParams = "?"
        if options.item
          fields = "q.field=fitness"
          values = "&q.value=#{$scope.queryGist}"
          op = "&q.op=eq"
          historyParams = "?#{fields}#{values}#{op}"
          item = options.item
          url = "#{baseURL}#{item}#{historyParams}"
        else
          url = "#{baseURL}#{queryParams}"
        return url

    init_realtime = () ->
      count = 0
      data = []
      date = (new Date()).getTime()
      loop
        break if count >= _DEFAULT_SET_LENGTH
        data.push {
          x: date - (_DEFAULT_SET_LENGTH - count) * 10000
          y: 0
        }
        count += 1
      return data

    $scope.writeRate = {
      title: _('Write Rate')
      unit: 'B/S'
      real_time: $scope.realTime
      series: [{
        name: _('Write Rate'),
        data: (() ->
          if $scope.realTime
            return init_realtime()
          data = []
          url = getURL({
            baseURL: meterURL,
            item: 'ceph.write.bytes.rate',
            limit: _DEFAULT_SET_LENGTH,
            q: query
          })
          $http.get(url)
            .then (response) ->
              if response.status == 200
                for meter in response.data.reverse()
                  time = meter.timestamp
                  value = meter.counter_volume
                  data.push({
                    x: Date.parse(time)
                    y: parseFloat((Number(value)).toFixed(2))
                  })
          return data
        )()
      }]
    }
    $scope.readRate = {
      title: _('Read Rate')
      unit: 'B/S'
      real_time: $scope.realTime
      series: [{
        name: _('Read Rate'),
        data: (() ->
          if $scope.realTime
            return init_realtime()
          data = []
          url = getURL({
            baseURL: meterURL,
            item: 'ceph.read.bytes.rate',
            limit: _DEFAULT_SET_LENGTH,
            q: query
          })
          $http.get(url)
            .then (response) ->
              if response.status == 200
                for meter in response.data.reverse()
                  time = meter.timestamp
                  value = meter.counter_volume
                  data.push({
                    x: Date.parse(time)
                    y: parseFloat((Number(value)).toFixed(2))
                  })
          return data
        )()
      }]
    }

    $scope.operationsRate = {
      title: _('Operations Rate')
      unit: _ 'times'
      real_time: $scope.realTime
      series: [{
        name: _('Operations Rate'),
        data: (() ->
          if $scope.realTime
            return init_realtime()
          data = []
          url = getURL({
            baseURL: meterURL,
            item: 'ceph.operations.rate',
            limit: _DEFAULT_SET_LENGTH,
            q: query
          })
          $http.get(url)
            .then (response) ->
              if response.status == 200
                for meter in response.data.reverse()
                  time = meter.timestamp
                  value = meter.counter_volume
                  data.push({
                    x: Date.parse(time)
                    y: parseFloat((Number(value)).toFixed(2))
                  })
          return data
        )()
      }]
    }
