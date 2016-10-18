'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.admin.hotspot')
  .controller 'admin.hotspot.HotspotCtr', ($scope, $http, $window, $q,
                                     $state, $interval, $templateCache,
                                     $compile, $animate, $modal) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.note =
      title: _("Hotspot monitoring")
      map:
        title: _(" Resource Hostspot Monitoring Map")
        Xtitle: _("CPU util")
        Ytitle: _("Memory usage")
    $scope.mapMarginLeft = 0
    $scope.move = {}

    clusterHttp = $http.get "#{serverUrl}/os-aggregates"
    cpuHttp = $http.get "#{serverUrl}/aggregate/cpu_util/host"
    memHttp = $http.get "#{serverUrl}/aggregate/memory.usage/host"
    $q.all [clusterHttp, cpuHttp, memHttp]
      .then (res) ->
        clusters = res[0].data
        cpus = res[1].data.data
        mems = res[2].data.data
        metrics =
          'cpu_util': cpus
          'memory.usage': mems
        clusters = utils.initialClusters clusters, metrics
        $scope.clusters = clusters
        if clusters.length
          $scope.selected = 0

    # generate range.
    $scope.getRange = (len) ->
      len = len || 10
      return new Array(len)

    # select cluster.
    $scope.chooseCluster = (index) ->
      $scope.selected = index

    # If tow point is very close: x/y delta is less then width / 2,
    # show all points with status and name, otherwise show name of
    # this mouse hovered host point.
    $scope.getPointDesc = ($event, index) ->
      tHost = $scope.clusters[$scope.selected].hosts[index]
      if tHost.cHosts and tHost.cHosts.length
        $scope.clusters[$scope.selected].hosts[index].showNearPoints = true
        return true
      else if tHost.cHosts and not tHost.cHosts.length
        $scope.clusters[$scope.selected].hosts[index].showTip = true
        return true
      $this = angular.element($event.target).parent()
      $siblings = $this.siblings()
      width = $this.width()
      height = $this.height()
      left = parseInt $this.css('left')
      top = parseInt $this.css('top')
      nodeList = [$this]
      $siblings.each (ind) ->
        cLeft = parseInt $siblings.eq(ind).css('left')
        cTop = parseInt $siblings.eq(ind).css('top')
        deltaX = Math.abs cLeft - left
        deltaY = Math.abs cTop - top
        if deltaX < width / 2 and deltaY < height / 2
          nodeList.push $siblings.eq(ind)
      if nodeList.length == 1
        $scope.clusters[$scope.selected].hosts[index].showTip = true
        $scope.clusters[$scope.selected].hosts[index].cHosts = []
        return true
      cHosts = []
      for node in nodeList
        classes = node[0].className
        host =
          name: node.attr('point-title')
          classes: classes
          index: node.attr('point-index')
        cHosts.push host
      $scope.clusters[$scope.selected].hosts[index].cHosts = cHosts
      $scope.clusters[$scope.selected].hosts[index].showNearPoints = true

    # hide host point tips.
    $scope.hidePointDesc = (index) ->
      $scope.clusters[$scope.selected].hosts[index].showNearPoints = false
      $scope.clusters[$scope.selected].hosts[index].showTip = false

    $scope.toLeft = ->
      if $scope.mapMarginLeft >= 180
        $scope.mapMarginLeft -= 180

      if $scope.mapMarginLeft < 180
        $scope.move.leftDisabled = 'disabled'

    $scope.toRight = ->
      con = angular.element "#_hotspot_small_container"
      deltaX = con[0].scrollWidth - con.width()
      if deltaX > 0
        $scope.mapMarginLeft += 180

      if deltaX <= 0
        $scope.move.rightDisabled = 'disabled'

    # show point panel.
    $scope.choosePoint = (host) ->
      modalInstance = $modal.open {
        windowClass: 'window-hotspot'
        backdrop: 'static'
        templateUrl: '/scripts/dashboards/admin/hotspot/views/_detail.html'
        controller: 'admin.hotspot.DetailCtl'
        resolve:
          $host: ->
            return host
          $cluster: ->
            return $scope.clusters[$scope.selected]
      }

  .controller 'admin.hotspot.DetailCtl', ($scope, $http, $q, $window, $host, $cluster) ->
    serverUrl = $CROSS.settings.serverURL
    hostInfo = $host['memory.usage'] || $host['cpu_util']
    $scope.clusterName = $cluster.name
    $scope.note =
      title: _("Host info")
      noAvailableHosts: _("No available host in this cluster")
      defaultCluster: _("Host not in any cluster by default(In Default view).")
      host:
        title: _("Recommend host(Drag instance point to host for migration)")
        name: _("Name")
        ip: _("IP")
        cpu: _("CPU num")
        mem: _("Memory Capacity")
        usedMem: _("Used memory")
        memUsage: _("Memory usage")
        cpuUsage: _("CPU usage")
      instance:
        title: _("Running instances behind")
        empty: _("No instances running.")
        name: _("Name")
        cpu: _("CPU num")
        mem: _("Memory Capacity")
        userName: _("User name")
        projectName: _("Project name")
        memUsage: _("Memory usage")
        cpuUsage: _("CPU usage")
      action:
        migrate: _("Migrate instance")

    # initial host info.
    host = JSON.parse hostInfo.meter_data
    memory_mb = host['memory_mb']
    h_usage = $host['memory.usage']
    if memory_mb
      host['memory_mb'] = $cross.utils.getRamFix memory_mb
    if host['memory_mb_used']
      if memory_mb and h_usage and h_usage.value != undefined
        host['memory_mb_used'] = memory_mb * h_usage.value
        host['memory_mb_used'] = $cross.utils.getRamFix(host['memory_mb_used'] / 100)
      else
        host['memory_mb_used'] = $cross.utils.getRamFix host['memory_mb_used']

    host = host || {}
    host.name = hostInfo.id
    host.usage =
      cpu:
        unit: $host['cpu_util'].unit
        value: $host['cpu_util'].value
        level: $host['cpu_util'].level
      memory:
        unit: $host['memory.usage'].unit
        value: $host['memory.usage'].value
        level: $host['memory.usage'].level
    $scope.host = host

    # get instance mem/cpu monitoring data.
    params =
      params:
        host_name: host.name
    insParams =
      params:
        all_tenants: true
        host: host.name
    cpuHttp = $http.get "#{serverUrl}/aggregate/cpu_util/instance", params
    memHttp = $http.get "#{serverUrl}/aggregate/memory.usage/instance", params
    insHttp = $http.get "#{serverUrl}/servers", insParams
    $q.all [cpuHttp, memHttp, insHttp]
      .then (res) ->
        cpus = res[0].data.data
        mems = res[1].data.data
        instances = res[2].data.data
        metrics =
          'cpu_util': cpus
          'memory.usage': mems
        $scope.host.instances = utils.rankInstance instances, metrics

    # show available hosts.
    $scope.showAvailableHost = ->
      $scope.showHosts = true
      clusterHttp = $http.get "#{serverUrl}/os-aggregates"
      cpuHttp = $http.get "#{serverUrl}/aggregate/cpu_util/host"
      memHttp = $http.get "#{serverUrl}/aggregate/memory.usage/host"
      $q.all [clusterHttp, cpuHttp, memHttp]
        .then (res) ->
          clrs = res[0].data
          cpus = res[1].data.data
          mems = res[2].data.data
          mtrs =
            'cpu_util': cpus
            'memory.usage': mems
          clsName = $cluster.name
          hstName = host.name
          availableHosts = utils.initialCluster clrs, mtrs, clsName, hstName
          $scope.availableHosts = availableHosts

    # Handle panel close action.
    $scope.cancel = ->
      $scope.$close()

    # Handle migrate action.
    $scope.migrate = ($event, instance, avHost) ->
      params = {
        disk_over_commit: true
        block_migration: false
        host: avHost.name
      }
      params.instanceId = instance.id
      $scope.showLoading = true
      $cross.instanceAction 'live-migrate', $http, $window, params, (status) ->
        name = instance.name
        if status == 200
          msg = _("Migrate instance ") + name + _(" to ")
          msg += $scope.host.name + _(" successful")
          toastr.success msg
        else
          msg = _("Migrate instance ") + name + _(" to ")
          msg += $scope.host.name + _(" failed")
          toastr.error msg
        $scope.showLoading = false

utils =
  DEFAULT_CLUSTER: 'Default'
  ALLOW_MIGRATE_STATUS: ['ACTIVE']
  MAX_AVAILABLE_HOSTS: 6
  ###
  # build a metrics dict with keys of item id.
  ###
  _buildMetricDict: (metrics) ->
    mDict = {}
    for metric of metrics
      for item in metrics[metric]
        if not mDict[item.id]
          mDict[item.id] = {}
        mDict[item.id][metric] = item
    return mDict

  ###
  # build a instances dict.
  ###
  _buildInstancesDict: (instances, metrics) ->
    mDict = {}
    for instance in instances
      if instance.status in utils.ALLOW_MIGRATE_STATUS
        mDict[instance.id] =
          allowMig: true
          ram: $cross.utils.getRamFix instance.ram
          vcpus: instance.vcpus
          id: instance.id
          name: instance.name
          userName: instance['user_name']
          projectName: instance['project_name']
      else
        continue
    for metric of metrics
      for item in metrics[metric]
        if not mDict[item.id]
          continue
        mDict[item.id][metric] = item
    return mDict

  ###
  # Get instances list with rank.
  ###
  rankInstance: (instances, metrics) ->
    iDict = utils._buildInstancesDict instances, metrics
    if not Object.keys(iDict).length
      return []
    rankInsts = []
    for insId of iDict
      index = 0
      instance = iDict[insId]
      if not instance['cpu_util']
        instance['cpu_util'] = {}
      if not instance['memory.usage']
        instance['memory.usage'] = {}
      memUsage = instance['memory.usage'].value || 0
      cpuUtil = instance['cpu_util'].value || 0
      maxer = Math.max cpuUtil, memUsage
      for ins in rankInsts
        curCpu = ins['cpu_util'].value || 0
        curMem = ins['memory.usage'].value || 0
        curMaxer = Math.max curCpu, curMem
        if curMaxer < maxer
          break
        else if curMaxer == maxer
          if curCpu < cpuUtil or curMem < memUsage
            break
        index += 1
      instance.rank = maxer
      rankInsts.splice(index, 0, instance)
    if rankInsts.length
      INS_EACH_ROW = 10
      adder = INS_EACH_ROW - rankInsts.length % INS_EACH_ROW
      index = 0
      loop
        break if index >= adder
        rankInsts.push {}
        index += 1
    return rankInsts

  initialCluster: (clusters, metrics, cluster, hostName) ->
    mDict = utils._buildMetricDict metrics
    hosts = []
    for cl in clusters
      if cl.name != cluster
        continue
      computeNodes = cl.hosts
      if not computeNodes or not computeNodes.length
        continue
      for host in computeNodes
        break if hosts.length >= utils.MAX_AVAILABLE_HOSTS
        name = host
        if name == hostName
          continue
        if not mDict[name]
          continue
        index = 0
        if not mDict[name]['cpu_util']
          mDict[name]['cpu_util'] = {}
        if not mDict[name]['memory.usage']
          mDict[name]['memory.usage'] = {}
        cpuV = mDict[name]['cpu_util'].value || 0
        memV = mDict[name]['memory.usage'].value || 0
        maxer = Math.max cpuV, memV
        for h in hosts
          if maxer > h.maxer
            break
          else if maxer == h.maxer
            if h['cpu_util'].value > cpuV or h['memory.usage'].value > memV
              break
            index += 1
        hostInfo = mDict[name]['memory.usage'].meter_data
        hostInfo = hostInfo or mDict[name]['cpu_util'].meter_data
        hostInfo = JSON.parse hostInfo
        memory_mb = hostInfo['memory_mb']
        if memory_mb
          hostInfo['memory_mb'] = $cross.utils.getRamFix memory_mb
        if hostInfo['memory_mb_used']
          if memory_mb and mDict[name]['memory.usage']
            hostInfo['memory_mb_used'] = memory_mb * mDict[name]['memory.usage'].value
            hostInfo['memory_mb_used'] = $cross.utils.getRamFix(hostInfo['memory_mb_used'] / 100)
          else
            hostInfo['memory_mb_used'] = $cross.utils.getRamFix hostInfo['memory_mb_used']
        hostInfo.maxer = maxer
        hostInfo.name = name
        hostInfo['cpu_util'] = mDict[name]['cpu_util']
        hostInfo['memory.usage'] = mDict[name]['memory.usage']
        hosts.splice index, 0, hostInfo
    return hosts

  initialClusters: (clusters, metrics) ->
    buildCluster = []
    mDict = utils._buildMetricDict metrics
    for cl in clusters
      computeNodes = cl.hosts
      if not computeNodes or not computeNodes.length
        continue
      cuCluster =
        name: cl.name
        hosts: []
      for host in computeNodes
        if not mDict[host]
          continue
        mDict[host].name = host
        cuCluster.hosts.push mDict[host]
        delete mDict[host]
      buildCluster.push cuCluster
    if Object.keys(mDict).length
      cuCluster =
        name: utils.DEFAULT_CLUSTER
        hosts: []
      for host of mDict
        mDict[host].name = host
        cuCluster.hosts.push mDict[host]
      buildCluster.push cuCluster
    return buildCluster
