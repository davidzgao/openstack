'use strict'

# TODO(ZhengYue): Optimize this controller:
# Extract common code of each object of monitor item,
# simplify code and make logic clear.

angular.module('Cross.admin.compute_node')
  .controller 'admin.compute_node.HostMonitorCtr', ($scope,
  $stateParams, $http, $window) ->
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

    currentHostId = $stateParams.hostId
    $scope.currentHostName = $stateParams.hostName

angular.module('Cross.admin.compute_node')
  .controller 'admin.compute_node.HostMonitorRealTimeCtl', ($scope,
  $http,$window, $q, $stateParams, $state, $gossip) ->
    _DEFAULT_SET_LENGTH = 10
    $scope.indicatorSet = {
      'cpu_util': _('CPU Util')
      'mem_util': _('Memory Util')
      'disk_util': _('Disk Util')
      'network_util': _('Network Usage')
      'tip': _('Temporarily no data!')
    }

    # Orginize the query params
    # Common query params for cpu_util/memory.usage/disk.*.rate
    query = {
      limit: _DEFAULT_SET_LENGTH
      'q.field': 'resource_id'
      'q.op': 'eq'
      'q.value': $scope.currentHostName
    }
    meterURL = $window.$CROSS.settings.serverURL + '/meters/'
    resourceURL = $window.$CROSS.settings.serverURL + '/resources_per'

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
        $gossip.destroyRealtime $scope.currentHostName
      $gossip.startRealtime $scope.currentHostName

    getURL = (options) ->
      q = options.q
      baseURL = options.baseURL
      queryParams = options.baseURL
      if $scope.queryGist == 'time'
        if options.limit
          limit = options.limit
          queryParams = "?limit=#{limit}&q.field=#{q['q.field']}&q.op=#{q['q.op']}&q.value=#{q['q.value']}"
        else
          queryParams = "?q.field=#{q['q.field']}&q.op=#{q['q.op']}&q.value=#{q['q.value']}"
        if options.item
          item = options.item
          url = "#{baseURL}#{item}#{queryParams}"
        else
          url = "#{baseURL}#{queryParams}"
        return url
      else
        queryParams = "?q.field=#{q['q.field']}&q.op=#{q['q.op']}&q.value=#{q['q.value']}"
        if options.item
          fields = "q.field=#{q['q.field']}&q.field=fitness"
          values = "&q.value=#{q['q.value']}&q.value=#{$scope.queryGist}"
          op = "&q.op=#{q['q.op']}&q.op=eq"
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

    $scope.cpuUtil = {
      title: _('CPU Util')
      unit: '%'
      real_time: $scope.realTime
      flag:
        loading: true
        error: false
        null: false
      series: [{
        name: _('CPU Util'),
        data: (() ->
          if $scope.realTime
            return init_realtime()
          data = []
          url = getURL({
            baseURL: meterURL,
            item: 'cpu_util',
            limit: _DEFAULT_SET_LENGTH,
            q: query
          })
          $http.get(url)
            .success (response) ->
              self = $scope.cpuUtil.flag
              self.loading = false
              if response.length == 0
                self.null = true
                data.push {x: null, y: null}
              for meter in response.reverse()
                time = meter.timestamp
                value = meter.counter_volume
                data.push({
                  x: Date.parse(time)
                  y: parseFloat((Number(value)).toFixed(2))
                })
            .error (err) ->
              self = $scope.cpuUtil.flag
              self.loading = false
              self.error = true
              self.null = true
          return data
        )()
      }]
    }
    $scope.ramUtil = {
      title: _('Memory Util')
      unit: '%'
      real_time: $scope.realTime
      flag:
        loading: true
        error: false
        null: false
      series: [{
        name: _('Memory Util'),
        data: (() ->
          if $scope.realTime
            return init_realtime()
          data = []
          url = getURL({
            baseURL: meterURL,
            item: 'memory.usage',
            limit: _DEFAULT_SET_LENGTH,
            q: query
          })
          $http.get(url)
            .success (response) ->
              self = $scope.ramUtil.flag
              self.loading = false
              if response.length == 0
                self.null = true
                data.push {x: null, y: null}
              for meter in response.reverse()
                time = meter.timestamp
                value = meter.counter_volume
                data.push({
                  x: Date.parse(time)
                  y: parseFloat((Number(value)).toFixed(2))
                })
            .error (err) ->
              self = $scope.ramUtil.flag
              self.loading = false
              self.error = true
              self.null = true
          return data
        )()
      }]
    }

    $scope.diskDataStatus = {
      diskReadLoading: null
      diskWriteLoading: null
    }

    $scope.$watch 'diskDataStatus', (newVal, oldVal) ->
      if newVal.diskReadLoading == false and\
      newVal.diskWriteLoading == false
        $scope.diskDataStatus.diskDataLoading = false
        if $scope.diskReadNull and $scope.diskWriteNull
          $scope.diskDataStatus.diskDataNull = true
      else
          $scope.diskDataStatus.diskDataLoading = true
    , true

    $scope.diskUsage = {
      title: _('Disk Util')
      unit: 'B/S'
      real_time: $scope.realTime
      series: [{
        name: _('Disk Read Rate'),
        data: (() ->
          if $scope.realTime
            return init_realtime()
          $scope.diskDataStatus.diskReadLoading = true
          data = []
          url = getURL({
            baseURL: meterURL
            item: 'disk.read.bytes.rate'
            limit: _DEFAULT_SET_LENGTH
            q: query
          })
          $http.get(url)
            .success (response) ->
              $scope.diskDataStatus.diskReadLoading = false
              if response.length == 0
                $scope.diskReadNull = true
              else
                $scope.diskReadNull = false
              for meter in response.reverse()
                time = meter.timestamp
                value = meter.counter_volume
                data.push({
                  x: Date.parse(time)
                  y: parseFloat((Number(value)).toFixed(2))
                })
            .error (err) ->
              $scope.diskDataStatus.diskReadLoading = false
              $scope.diskDataStatus.diskDataNull = true

          return data
        )()
      },
      {
        name: _('Disk Write Rate'),
        data: (() ->
          if $scope.realTime
            return init_realtime()
          $scope.diskDataStatus.diskWriteLoading = true
          data = []
          url = getURL({
            baseURL: meterURL
            item: 'disk.write.bytes.rate'
            limit: _DEFAULT_SET_LENGTH
            q: query
          })
          $http.get(url)
            .success (response) ->
              $scope.diskDataStatus.diskWriteLoading = false
              if response.length == 0
                $scope.diskWriteNull = true
              else
                $scope.diskWriteNull = false
              for meter in response.reverse()
                time = meter.timestamp
                value = meter.counter_volume
                data.push({
                  x: Date.parse(time)
                  y: parseFloat((Number(value)).toFixed(2))
                })
            .error (err) ->
              $scope.diskDataStatus.diskWriteLoading = false
              $scope.diskDataStatus.diskDataNull = true
          return data
        )()
      }]
    }

    # NOTE (ZhengYue):
    # The way for obtain network monitor is different from others
    # The step of obtain instance's network monitor data as follow:
    #   1. Get nics which belongs to current instance;
    #   2. Iterate the nics to get the resource_id for each nic;
    #   3. Use the each nic's resource_id to get network traffic,
    #      contain: network.incoming.bytes.rate and
    #      network.outgoing.bytes.rate.

    net_query = $scope.currentHostName + '-'
    nicsQuery = {
      'q.field': 'resource_id'
      'q.op': 'eq'
      'q.value': '{"$regex": "^' + net_query + '"}'
    }
    resourcesURL = getURL({
      baseURL: resourceURL
      q: nicsQuery
    })

    $scope.networkDataStatus = {
      readLoading: null
      writeLoading: null
    }

    $scope.$watch 'networkDataStatus', (newVal, oldVal) ->
      if newVal.readLoading == false and\
      newVal.writeLoading == false
        $scope.networkDataStatus.dataLoading = false
        if $scope.networkReadNull and $scope.networkWriteNull
          $scope.networkDataStatus.dataNull = true
      else
          $scope.networkDataStatus.dataLoading = true
    , true

    $scope.instanceNics = []

    $scope.networkUsages = {}
    $http.get(resourcesURL)
      .then (response) ->
        for nic in response.data
          #if nic.metadata.name.indexOf("eth") != 0
          #  continue
          $scope.instanceNics.push nic
          networkTrafficQuery = {
            'q.field': 'resource_id'
            'q.op': 'eq'
            'q.value': nic.resource_id
          }
          $scope.networkUsages[nic.metadata.name] = {
            title: nic.metadata.name
            unit: 'B/S'
            real_time: $scope.realTime
            series: [{
              name: _('Network Incoming Rate'),
              data: (() ->
                if $scope.realTime
                  return init_realtime()
                $scope.networkDataStatus.writeLoading = true
                data = []
                url = getURL({
                  baseURL: meterURL
                  item: 'network.incoming.bytes.rate'
                  limit: _DEFAULT_SET_LENGTH
                  q: networkTrafficQuery
                })
                $http.get(url)
                  .success (res) ->
                    $scope.networkDataStatus.writeLoading = false
                    if res.length == 0
                      $scope.networkWriteNull = true
                    else
                      $scope.networkWriteNull = false
                    if res.length > 0
                      for meter in res.reverse()
                        time = meter.timestamp
                        value = meter.counter_volume
                        data.push({
                          x: Date.parse(time)
                          y: parseFloat((Number(value)).toFixed(2))
                        })
                    else
                      data.push({
                        x: 0
                        y: _('No Data')
                      })
                    # (TODO): Raise a tips
                    #else if res.status != 200
                  .error (err) ->
                    $scope.networkDataStatus.writeLoading = false
                    $scope.networkDataStatus.dataNull = true
                return data
              )()
            },
            {
              name: _('Network Outgoing Rate'),
              data: (() ->
                if $scope.realTime
                  return init_realtime()
                $scope.networkDataStatus.readLoading = true
                data = []
                url = getURL({
                  baseURL: meterURL
                  item: 'network.outgoing.bytes.rate'
                  limit: _DEFAULT_SET_LENGTH
                  q: networkTrafficQuery
                })
                $http.get(url)
                  .success (res) ->
                    $scope.networkDataStatus.readLoading = false
                    if res.length == 0
                      $scope.networkReadNull = true
                    else
                      $scope.networkReadNull = false
                    if res.length > 0
                      for meter in res.reverse()
                        time = meter.timestamp
                        value = meter.counter_volume
                        data.push({
                          x: Date.parse(time)
                          y: parseFloat((Number(value)).toFixed(2))
                        })
                    else
                      data.push({
                        x: 0
                        y: _('No Data')
                      })
                    # (TODO): Raise a tips
                    #else if res.status != 200
                  .error (err) ->
                      $scope.networkDataStatus.writeLoading = false
                      $scope.networkDataStatus.dataNull = true
                return data
              )()
            }]
          }
