'use strict'
###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module("Cross.admin.overview")
  .controller "admin.overview.OverviewCtr", ($scope, $http, $q, $window) ->
    # Initial note.
    $scope.note =
      resource:
        vm: $window._ "VMs"
        host: $window._ "PMs"
        cluster: $window._ "Clusters"
        unit: $window._ "num"
      usage:
        lead: $window._ "Resource usage"
        vcpu: $window._ "CPU"
        ram: $window._ "Memory"
        volume: $window._ "Volume"
        floatingIP: $window._ "Public IP"
      unit:
        num: _("Num")
        core: _("cores")
        gb: _("GB")
      topology:
        lead: $window._ "Hosts topology"
      hotspot:
        lead: _("Hotspot monitoring rank")
        detail: _("Detail")
        empty: _("No compute nodes")
      message:
        lead: $window._ "Latest message"
        more: $window._ "more"
        empty: $window._ "No workflow messages"
      alarm:
        lead: $window._ "Latest Alarm"
        empty: $window._ "No alarm notifications"

    if $CROSS.settings.use_neutron
      $scope.useNeutron = true
    else
      $scope.useNeutron = false
    $scope.useFederator = $window.$CROSS.settings.useFederator or false
    $scope.enable_ceph = $window.$CROSS.settings.enable_ceph || false
    $scope.storageWarning = $window.$CROSS.settings.storageWarning || 90
    $scope.cpuOverDistribute = $window.$CROSS.settings.cpuOverDistribute || 16
    $scope.cpuWarning = $window.$CROSS.settings.cpuWarning || 90
    $scope.parseResponse = (storage) ->
      # Parse data from response
      # Data for storage overview
      usageRatio = storage.used / storage.total
      $scope.usageWarn = 'normal'
      if usageRatio * 100 > $scope.usageThreshold
        $scope.usageWarn = 'warn'
      $scope.usageTatioText = "#{usageRatio.toFixed(2) * 100}%"
      usageRatio = usageRatio.toFixed(2) * 100

    baseURL = $window.$CROSS.settings.serverURL

    if $scope.useFederator
      httpStorage = $http.get "#{baseURL}/storage/usage"
      $q.all [httpStorage]
        .then (value) ->
          volumeTotal = value[0].data.total
          volumeUsed = value[0].data.total - value[0].data.free
          volume = 0
          if volumeTotal
            volume = 100 * volumeUsed
            volume /= volumeTotal
            volume = Math.round volume
          if $scope.enable_ceph or $scope.useFederator
            $scope.note.usage.volume = _ 'Storage'
            volumeUsed = $cross.utils.getByteFix volumeUsed
            volumeTotal = $cross.utils.getByteFix volumeTotal
          volumeState = 'ok'
          if volume > $cross.topologyUtils._WARN_THREATHOLD_
            volumeState = 'warn'
          $scope.usage.volume = volume
          $scope.usage.volumeTotal = volumeTotal
          $scope.usage.volumeUsed = volumeUsed
          $scope.usage.volumeState = volumeState
          $scope.usage.volumeHadGot = true
        .catch (error) ->
          console.error "Failed to get storage usage: #{error}"

    resourceURL = $window.$CROSS.settings.serverURL + '/resources_per'
    storageURL = 'q.field=resource_id&q.op=eq&q.value=ceph&q.type=string'
    httpUsageRatio = $http.get "#{resourceURL}?#{storageURL}"
    httpClusters = $http.get "#{baseURL}/os-aggregates"
    httpStatistic = $http.get "#{baseURL}/os-hypervisors/statistics"
    httpFloatingIp = $http.get "#{baseURL}/os-floating-ips-bulk"
    httpHyper = $http.get "#{baseURL}/os-hypervisors/detail"
    queryStrings = "?limit_from=0&limit_to=0&all_tenants=true"
    httpInstances = $http.get "#{baseURL}/servers#{queryStrings}"
    resources = [
      httpClusters, httpStatistic,
      httpFloatingIp, httpHyper
      httpInstances
    ]
    resources.push(httpUsageRatio) if $scope.enable_ceph
    $q.all(resources)
      .then (values)->
        clusters = values[0].data
        statistic = values[1].data
        ips = values[2].data
        if values[5] && values[5].data
          if $scope.useFederator
            otherStorage = values[5].data
            otherStorage.used = otherStorage.total - otherStorage.free
          else if $scope.enable_ceph
            otherStorage = values[5].data[0] \
                           and values[5].data[0].metadata \
                           or {total: 0, used: 0}
          else
            # NOTE: Fake metadata used at ceph montor data is null
            otherStorage = {
              total:100
              used: 0
            }
        # TODO(liuhaobo): add $scope,cephUsage parameters for getUsage()
        # cephUsage is used to binding ceph type of storage
        stats = $cross.topologyUtils.getUsage clusters, statistic, ips, $scope, otherStorage

        # handle vcpu usage.
        stats.vcpu = 0
        if stats.vcpuTotal
          stats.vcpu = 100 * stats.vcpuUsed / stats.vcpuTotalOver
          stats.vcpu = Math.round stats.vcpu
        stats.vcpuState = 'ok'
        if stats.vcpu > $cross.topologyUtils._WARN_THREATHOLD_
          stats.vcpuState = 'warn'
        stats.vcpuTotal = "#{stats.vcpuTotal}"
        stats.vcpuHadGot = true

        # handle memory usage.
        stats.ram = 0
        if stats.ramTotal
          stats.ram = 100 * stats.ramUsed / stats.ramTotal
          stats.ram = Math.round stats.ram
        stats.ramState = 'ok'
        if stats.ram > $cross.topologyUtils._WARN_THREATHOLD_
          stats.ramState = 'warn'
        stats.ramTotal = $cross.utils.rand(stats.ramTotal / 1024)
        stats.ramUsed = $cross.utils.rand(stats.ramUsed / 1024)
        stats.ramHadGot = true

        # handle volume usage.
        stats.volume = 0
        if stats.volumeTotal
          stats.volume = 100 * stats.volumeUsed
          stats.volume /= stats.volumeTotal
          stats.volume = Math.round stats.volume
        if $scope.enable_ceph or $scope.useFederator
          $scope.note.usage.volume = _ 'Storage'
          stats.volumeUsed = $cross.utils.getByteFix stats.volumeUsed
          stats.volumeTotal = $cross.utils.getByteFix stats.volumeTotal
        stats.volumeState = 'ok'
        if stats.volume > $cross.topologyUtils._WARN_THREATHOLD_
          stats.volumeState = 'warn'
        stats.volumeHadGot = true

        # handle floating ip usage.
        if not $scope.useNeutron
          stats.floatingIP = 0
          if stats.floatingIPTotal
            stats.floatingIP = 100 * stats.floatingIPUsed
            stats.floatingIP /= stats.floatingIPTotal
            stats.floatingIP = Math.round stats.floatingIP
          stats.floatingIPState = 'ok'
          if stats.floatingIP > $cross.topologyUtils._WARN_THREATHOLD_
            stats.floatingIPState = 'warn'
          stats.floatingIPHadGot = true

        $scope.usage = stats

        # load resource statistic.
        hypers = values[3].data
        vms = values[4].data
        resource = $cross.topologyUtils.getResource clusters, hypers, vms
        resource.volumes = 10
        $scope.resource = resource
        hostView = $cross.topologyUtils.initialTopology clusters, hypers, vms
        $scope.topology =
          hostView: hostView
      , (err) ->
        console.log "Get resource with error: ", err

    getPoolLength = (pool) ->
      pat = /\d+.\d+.\d+.(\d+)/i
      matchRes = pat.exec(pool.start)
      if matchRes
        startPoint = parseInt(matchRes[1])
      else
        startPoint = 2
      endMatchRes = pat.exec(pool.end)
      if endMatchRes
        endPoint = parseInt(endMatchRes[1])
      else
        endPoint = 255
      return endPoint - startPoint + 1

    if $scope.useNeutron
      # NOTE: (ZhengYue): Can't directly get usage of floatingIPs at
      # neutron env. So accumulate allocation pool of subnet which
      # is subnet of public network.
      $http.get "#{baseURL}/networks", {
        params:
          "router:external": true
      }
        .success (data) ->
          networks = $http.get "#{baseURL}/networks?router:external=true"
          subnets = $http.get "#{baseURL}/subnets"
          ports = $http.get "#{baseURL}/ports", {
            params:
              network_id: data[0] and data[0].id
          }
          $q.all [networks, subnets, ports]
            .then (res) ->
              networkList = res[0].data
              subnetList = res[1].data
              floatingList = res[2].data
              pubSubs = []
              pubNets = {}
              floatingIpLength = 0
              for network in networkList
                pubNets[network.id] = network
              for subnet in subnetList
                if pubNets[subnet.network_id]
                  pubSubs.push subnet

              if pubSubs.length > 0
                poolLength = 0
                for pubSub in pubSubs
                  allocationPools = pubSub.allocation_pools
                  for pool in allocationPools
                    poolLength += getPoolLength(pool)
              else
                # NOTE: Set 253 as default length of floating ip pool
                poolLength = 253
              usedFloating = floatingList.length
              percentUsage = (usedFloating / poolLength) * 100
              $scope.usageNeutron = {
                floatingIP: Math.round percentUsage
                floatingIPUsed: usedFloating
                floatingIPTotal: poolLength
                floatingIPHadGot: true
              }


    cpuHttp = $http.get "#{baseURL}/aggregate/cpu_utils/host"
    memHttp = $http.get "#{baseURL}/aggregate/memory.usage/host"
    $q.all [cpuHttp, memHttp]
      .then (res) ->
        cpus = res[0].data.data
        mems = res[1].data.data
        metrics =
          'cpu_util': cpus
          'memory.usage': mems
        $scope.hostRanks = $cross.topologyUtils.hotspotRank metrics

    $cross.listWorkflowLog $http, $window, $q, {
      skip: 0
      limit: 8
      only_admin: 1
    }, (messages, total, localeTime) ->
      if not messages
        # TODO:(lixipeng) messages empty handle.
        return
      msgRec = []
      for message in messages
        m_dict =
          user: message.user_name
          content: message.traits.resource_type
        msgRec.push({
          creat_at: $cross.utils.prettyTime message.generated, localeTime, true
          content: _(["%(user)s had post a application of %(content)s", m_dict])
        })
      $scope.messages = msgRec

    dataQueryOpts =
      skip: 0
      limit: 8
    $cross.listAlarmLog $http, $window, $q, dataQueryOpts, (alarms, total, localeTime)->
      if not alarms
        # TODO:(lixipeng) messages empty handle.
        return
      alRec = []
      msg = ""
      for alarm in alarms
        alRec.push({
          creat_at: $cross.utils.prettyTime alarm.triggered_at, localeTime, true
          content: alarm.alarm_meta
        })
      $scope.alarms = alRec

    return

$cross.topologyUtils =
  _RANK_MAX_: 6
  _HYPERVISOR_TYPE_:
    qemu: "QEMU"
    vmware: "VMWare Vcenter"
  # Warn threathold.
  _WARN_THREATHOLD_: 90

  _initialHyperDict: (hypers) ->
    hyperDict = {}
    for hyper in hypers
      key = "host_#{hyper.hypervisor_hostname}"
      key = key.replace(/[\.#>\(\)]/g, '_')
      hyperDict[key] =
        name: hyper.hypervisor_hostname
        vms: "+"
    return hyperDict

  # initial topology
  initialTopology: (clusters, hypers, vms, specific) ->
    hostView =
      root:
        type: "root"
        children: []
        id: "root"
        parent: null
    hyperType = $cross.utils._HYPERVISOR_TYPE_

    hyperDict = $cross.topologyUtils._initialHyperDict hypers
    clusteredHyper = []
    for cluster in clusters
      hostView.root.children.push("cluster_#{cluster.id}")
      cluster_id = "cluster_#{cluster.id}"
      hostView[cluster_id] =
        type: "cluster"
        children: []
        id: cluster_id
        parent: "root"
        name: cluster.name
      for node in cluster.hosts
        node_id = node.replace(/[\.#>]/g, '_')
        clusteredHyper.push "host_#{node_id}"
        host_id = "host_qemu_#{node_id}"
        delete hyperDict[host_id]
        hostView[cluster_id].children.push(host_id)
        for hyper in hypers
          if node == hyper.hypervisor_hostname
            hostView[host_id] =
              type: "host"
              children: []
              id: host_id
              parent: cluster_id
              name: node
              not_show_children: true
              running_vms: "+"
              status: hyper.status
        continue
    noneClusterHosts = []
    for hyper of hyperDict
      if hyperDict[hyper]
        host_id = "host_qemu_#{hyper}"
        hostView[host_id] =
          type: "host"
          children: []
          id: host_id
          parent: "cluster_0"
          name: hyperDict[hyper].name
          not_show_children: true
          running_vms: hyperDict[hyper].vms
        if hyper not in clusteredHyper
          noneClusterHosts.push("host_qemu_#{hyper}")
    if noneClusterHosts.length and !specific
      hostView["cluster_0"] =
        type: "cluster"
        children: noneClusterHosts
        id: "cluster_0"
        parent: "root"
        name: "default"
      hostView.root.children.push("cluster_0")
    return hostView

  getResource: (clusters, hypervisors, instances) ->
    stats =
      clusters: clusters.length
      hosts: hypervisors.length
      vms: instances.total

    hyperType = $cross.utils._HYPERVISOR_TYPE_
    return stats

  ###*
  # Get resource usage.
  #
  ###
  getUsage: (clusters, statistic, ips, $scope, otherStorage) ->
    # build resource usage.
    stats = $cross.topologyUtils._caculateUsage clusters
    stats.vcpuTotal += statistic.vcpus
    stats.vcpuTotalOver = stats.vcpuTotal * $scope.cpuOverDistribute
    stats.vcpuUsed += statistic.vcpus_used
    stats.ramTotal += statistic.memory_mb
    stats.ramUsed += statistic.memory_mb_used
    if not $scope.enable_ceph and not $scope.useFederator
      stats.volumeTotal += statistic.local_gb
      stats.volumeUsed += statistic.local_gb_used
    else if $scope.enable_ceph
      stats.volumeTotal += otherStorage.total
      stats.volumeUsed += otherStorage.used
    ipUsage = $cross.topologyUtils._caculateFloatingIpUsage ips
    stats.floatingIPTotal = ipUsage.total
    stats.floatingIPUsed = ipUsage.used
    return stats

  _caculateFloatingIpUsage: (ips) ->
    ipUsage =
      used: 0
      total: ips.length
    for ip in ips
      if ip.project_id
        ipUsage.used += 1
    return ipUsage

  _caculateUsage: (clusters) ->
    statistic =
      vcpuTotal: 0
      vcpuUsed: 0
      volumeUsed: 0
      volumeTotal: 0
      ramUsed: 0
      ramTotal: 0
    return statistic

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
  # Get instances list with rank.
  ###
  hotspotRank: (metrics) ->
    hDict = $cross.topologyUtils._buildMetricDict metrics
    if not Object.keys(hDict).length
      return []
    hosts = []
    for name of hDict
      index = 0
      host = hDict[name]
      if not host['cpu_util']
        host['cpu_util'] = {}
      if not host['memory.usage']
        host['memory.usage'] = {}
      memUsage = host['memory.usage'].value || 0
      cpuUtil = host['cpu_util'].value || 0
      metricName = ''
      level = ''
      if cpuUtil > memUsage
        maxer = cpuUtil
        metricName = _('CPU util')
        level = host['cpu_util'].level
      else
        maxer = memUsage
        metricName = _('Memory usage')
        level = host['memory.usage'].level
      for ins in hosts
        curCpu = ins['cpu_util'].value || 0
        curMem = ins['memory.usage'].value || 0
        curMaxer = Math.max curCpu, curMem
        if curMaxer < maxer
          break
        else if curMaxer == maxer
          if curCpu < cpuUtil or curMem < memUsage
            break
        index += 1
      host.rank = maxer
      host.metric = metricName
      host.name = name
      host.level = level
      hosts.splice(index, 0, host)
    return hosts.slice 0, $cross.topologyUtils._RANK_MAX_
