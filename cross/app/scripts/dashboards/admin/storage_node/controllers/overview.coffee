'use strict'

angular.module 'Cross.admin.storage_node'
  .controller 'admin.storage_node.StorageOverviewCtr', ($scope, $http,
  $window, $q, $interval, $state) ->

    $scope.note =
      health: _("Health status")
      osd: _("OSD node stat")
      mon: _("Monitor node stat")
      usage: _("Storage usage")
      osdError: _("Down OSD")
      osdTotal: _("All OSD")
      monError: _("Down monitor")
      monTotal: _("All monitor")
    $scope.storage_area = {
      overview: _ "Overview"
      node_state: _ "Node Status"
      storage_topology: _ "Storage Topology"
      storage_resource_pool: _ "Storage Resource Pool"
    }
    $scope.storage_usage = {
      used: ''
      available: ''
      total: ''
    }
    $scope.pagingOptions = {
      pageSizes: [15, 25, 30]
      pageSize: 15
      currentPage: 1
    }
    $scope.columnDefs = [
      {
        field: "displayName"
        displayName: _ "Name"
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]">'
      }
      {
        field: "freeSize"
        displayName: _ "Free Size"
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field] | unitSwitch:[true, \'B\']">'
      }
      {
        field: "totalSize"
        displayName: _ "Total Size"
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field] | unitSwitch:[true, \'B\']">'
      }
      {
        field: "peakIOPS"
        displayName: _ "Peak IOPS"
        cellTemplate: '<div class="ngCellText" ng-bind="item.provision.peakIOPS">'
      }
      {
        field: "status"
        displayName: _ "Status"
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]">'
      }
    ]

    $scope.storagePoolOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: false
      columnDefs: $scope.columnDefs
      showFooter: false
      addition: $scope.addition
    }

    $scope.healthState = 'normal'
    $scope.healthStateText = _ 'Normal'

    $scope.usageUsed = _ "Used "
    $scope.usageTotal = _ "Total "
    $scope.usageThreshold = 80
    $scope.usageRatioText = ''

    $scope.loading = true

    $scope.storageLink = $CROSS.settings.storageLink

    $scope.useFederator = $CROSS.settings.useFederator

    resourceURL = $window.$CROSS.settings.serverURL + '/resources_per'
    storageURL = 'q.field=resource_id&q.op=eq&q.value=ceph&q.type=string'

    getNodeById = (nodes, ch_id) ->
      for node, index in nodes
        if !node
          continue
        if node.id == ch_id
          return index

    getNodeByName = (nodes, name) ->
      index = angular.forEach nodes, (node, index) ->
        if node['type'] == name
          return index
      return index

    injectChildren = (nodes, type) ->
      for node in nodes
        if !node
          continue
        if node.type == type
          node['children_nodes'] = []
          for children in node.children
            childrenNode = getNodeById(nodes, children)
            node['children_nodes'].push(nodes[childrenNode])
            delete nodes[childrenNode]
      newNodes = []
      for node in nodes
        if node
          newNodes.push node
      return newNodes

    $scope.parseResponse = (storage) ->
      # Parse data from response

      # Data for storage overview
      usageRatio = storage.used / storage.total
      $scope.storage_usage.used = $cross.utils.getByteFix storage.used
      $scope.storage_usage.available = $cross.utils.getByteFix storage.available
      $scope.storage_usage.total = $cross.utils.getByteFix storage.total
      $scope.usageWarn = 'normal'
      if usageRatio * 100 > $scope.usageThreshold
        $scope.usageWarn = 'warn'
      $scope.usageTatioText = "#{usageRatio.toFixed(2) * 100}%"
      usageRatio = usageRatio.toFixed(2) * 100
      re = ///^\d{0,3}(\.\d{0,1})$///
      if !re.test(usageRatio)
        dicInd = String(usageRatio).indexOf('.')
        usageRatio = String(usageRatio).substring(0, dicInd + 3)
      $scope.usageRatio = usageRatio
      if storage.overall_status == 'HEALTH_OK'
        $scope.healthState = 'normal'
        $scope.healthStateText = _ 'Normal'
      else
        $scope.healthState = 'error'
        $scope.healthStateText = _ 'Warning'

      $scope.loading = false

      # Get storage node data and prepare element
      mons_stat = JSON.parse(storage.mons_stat || '{}')
      osd_stat = JSON.parse(storage.osd_stat || '{}')
      nodeCounts = []
      mon =
        total: 0
        error: 0
      for node, stat of mons_stat
        mon.total += 1
        if stat == 'HEALTH_OK'
          stat = 'normal'
        else
          stat = 'error'
          mon.error += 1
        monNode =
          name: node
          status: stat
          type: 'mon'
        nodeCounts.push monNode
      osd =
        total: 0
        error: 0
      for node, stat of osd_stat
        osd.total += 1
        if stat == 1 or stat == '1'
          stat = 'normal'
        else
          stat = 'error'
          osd.error += 1
        osdNode =
          name: node
          status: stat
          type: 'osd'
        nodeCounts.push osdNode
      $scope.mon = mon
      $scope.osd = osd
      NODE_IN_ON_ROW = 15
      len = nodeCounts.length
      left = NODE_IN_ON_ROW - len % NODE_IN_ON_ROW
      loop
        break if left <= 0
        nodeCounts.push {}
        left -= 1
      $scope.nodeCounts = nodeCounts

      modelData = JSON.parse(storage.model || '{}')
      nodes = []
      nodes = modelData['nodes']
      nodes = injectChildren(nodes, 'host')
      nodes = injectChildren(nodes, 'rack')
      nodes = injectChildren(nodes, 'root')
      rootNode = nodes[0]
      $scope.storageNodes = rootNode
      topologyArea = angular.element("#ceph-topology")
      $cross.ceph.renderNodes rootNode, topologyArea


    parseResponse = (storage) ->
      # Parse data from response

      # Data for storage overview
      storageInUse = storage.total - storage.free
      usageRatio = storageInUse / storage.total
      $scope.storage_usage.used = $cross.utils.getByteFix storageInUse
      $scope.storage_usage.available = $cross.utils.getByteFix storage.free
      $scope.storage_usage.total = $cross.utils.getByteFix storage.total
      $scope.usageWarn = 'normal'
      if usageRatio * 100 > $scope.usageThreshold
        $scope.usageWarn = 'warn'
      $scope.usageTatioText = "#{usageRatio.toFixed(2) * 100}%"
      usageRatio = usageRatio.toFixed(2) * 100
      re = ///^\d{0,3}(\.\d{0,1})$///
      if !re.test(usageRatio)
        dicInd = String(usageRatio).indexOf('.')
        dicInd = 0 if dicInd == -1
        usageRatio = String(usageRatio).substring(0, dicInd + 3)
      $scope.usageRatio = usageRatio
      $scope.loading = false

    $scope.setPagingData = (pagedData, total) ->
      $scope.storagePool = pagedData
      $scope.pageCounts = 1
      $scope.storagePoolOpts.data = $scope.storagePool
      $scope.storagePoolOpts.pageCounts = $scope.pageCounts

    if $scope.useFederator
      serverUrl = $CROSS.settings.serverURL
      $scope.getPagedDataAsync = ((pageSize, currentPage, callback) ->
        setTimeout(() ->
          $http.get "#{serverUrl}/storage/usage"
            .success (data) ->
              $scope.staData = data
              parseResponse data
              $scope.setPagingData data.detail
              (callback && typeof(callback) == "function") && callback()
            .error (err) ->
              toastr.error _("Failed load storage data.")
        , 300))($scope.pagingOptions.pageSize,
                $scope.pagingOptions.currentPage)

      $http.get "#{serverUrl}/storage/status"
        .success (data) ->
          if data.status == 'OK'
            $scope.healthState = 'normal'
            $scope.healthStateText = _ 'Normal'
          else if data.status == 'WARN'
            $scope.healthState = 'error'
            $scope.healthStateText = _ 'Warning'
        .error (err) ->
          toastr.error _("Failed load storage data.")
    else
      requestURL = "#{resourceURL}?#{storageURL}"
      $http.get(requestURL)
        .success (data, status, headers) ->
          storage_metadata = data[0].metadata
          $scope.storage_metadata = storage_metadata
          $scope.parseResponse(storage_metadata)
        .error (data, status, headers) ->
          toastr.error _("Failed load storage data.")
