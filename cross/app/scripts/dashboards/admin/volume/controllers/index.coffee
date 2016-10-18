'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.admin.volume')
  .controller 'admin.volume.VolumeCtr', ($scope, $http, $window, $q,
  $state, $interval, $stateParams) ->
    # Tabs at instance page
    $scope.tabs = [{
      title: _('Volume')
      slug: 'volume'
    }, {
      title: _('Volume snapshot')
      slug: 'snapshot'
    }]
    $scope.tabs.splice(1, 1) if $CROSS.settings.boot_from_volume
    if $stateParams.tab == 'backup'
      $scope.selectedTab = 'snapshot'
    else
      $scope.selectedTab = 'volume'
    $scope.changeTab = (name) ->
      params = null
      if name == 'snapshot'
        params = {tab: 'backup'}
      $state.go "admin.volume", params, {inherit: false}

  .controller 'admin.volume.VolumeTabCtr', ($scope, $http, $window, $q,
  $state, $interval, $selectedItem, $running, $deleted, $clearInterval, $gossipService) ->
    $scope.$on '$gossipService.volume', (event, meta) ->
      id = meta.payload.id
      serId = undefined
      changeAttach = false
      if meta.isInstance and meta.meta
        changeAttach = true
        if meta.event == 'instance.volume.attach'
          serId = id
        id = meta.meta['volume_id']
      if id == undefined
        return
      httpGets =  [$http.get "#{serverUrl}/volumes/#{id}"]
      if serId
        ids = [serId]
        params =
          params:
            ids: JSON.stringify ids
            fields: '["name"]'
        httpGets[1] = $http.get "#{serverUrl}/servers/query", params
      $q.all(httpGets).then (res) ->
        volume = res[0].data
        if res[1]
          nameDict = res[1].data[serId] || {}
          volume.attachments =
            id: serId
            name: nameDict.name
        if $scope.volumes
          counter = 0
          len = $scope.volumes.length
          loop
            break if counter >= len
            if $scope.volumes[counter].id == id
              break
            counter += 1
          if not volume
            $scope.volumes.splice counter, 1
            return
          volume.host = volume['os-vol-host-attr:host']
          if $scope.judgeStatus
            $scope.judgeStatus volume
            if counter < len and not changeAttach
              volume.attachments = $scope.volumes[counter].attachments
            $scope.volumes[counter] = volume
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.note =
      title: _("Volume")
      buttonGroup:
        delete: _("Delete")
        refresh: _("Refresh")

    # Category for instance action
    $scope.batchActionEnableClass = 'btn-disable'

    # For sort at table header
    $scope.sort = {
      reverse: false
      sortingOrder: 'created_at'
    }

    # For tabler footer and pagination or filter
    $scope.showFooter = true

    # Category for instance status
    $scope.labileStatus = [
      'creating'
      'error_deleting'
      'deleting'
      'attaching'
      'detaching'
      'downloading'
    ]
    $scope.abnormalStatus = [
      'error'
    ]

    notAttach = _("Not attach")

    volType =
      'data': _ "Data Volume"
      'data backup': _ "Data Volume Backup"
      'system': _ "System Volume"
      'system backup': _ "System Volume Backup"
      'image': _ "Image Volume"

    $scope.columnDefs = [
      {
        field: "display_name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.display_name}}"><a ui-sref="admin.volume.volumeId.overview({ volumeId:item.id })" ng-bind="item.display_name"></a></div>'
      }
      {
        field: "project"
        displayName: _("Project")
        cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.project}}"><a ui-sref="admin.project.projId.overview({ projId:item.tenant_id })" ng-bind="item.project"></a></div>'
      }
      {
        field: "size"
        displayName: _("Size(GB)")
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
      {
        field: "purposeDisplay"
        displayName: _("Type")
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
      {
        field: "attachName"
        displayName: _("Attach To")
        cellTemplate: '<div class="ngCellText" ng-if="item[col.field]">\
                       <a ui-sref="admin.instance.instanceId.overview({ instanceId:item.attachments })"\
                        ng-bind="item[col.field]?item[col.field]:\'' + notAttach + '\'"></a></div>\
                       <div class="ngCellText" ng-if="!item[col.field]"\
                        ng-bind="item[col.field]?item[col.field]:\'' + notAttach + '\'"></div>'
      }
      {
        field: "status",
        displayName: _("Status"),
        cellTemplate: '<div class="ngCellText status" ng-class="item.labileStatus"><i data-toggle="tooltip" data-placement="top" title="{{item.status}}"></i>{{item.status}}</div>'
      }
    ]
    federatorType =
      {
        field: "volume_type"
        displayName: _("Performance Type")
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
    if $CROSS.settings.useFederator
      $scope.columnDefs.splice 3, 0, federatorType
    # --End--

    $scope.searchKey = 'display_name'
    $scope.search = (key, value) ->
      pageSize = $scope.pagingOptions.pageSize
      if value == undefined or value == ''
        if $scope.searched
          $scope.pagingOptions.currentPage = 1
          $scope.refresResource()
          $scope.searched = false
          return
        else
          return
      if $scope.noSearchMatch
        if $scope.oldSearchValue
          if value.length > $scope.oldSearchValue.length
            return
      $scope.oldSearchValue = value
      $scope.pagingOptions.currentPage = 1
      currentPage = 1
      $scope.searched = true
      getPagedDataAsync pageSize, currentPage, (items) ->
        if items.length == 0
          $scope.noSearchMatch = true
        else
          $scope.noSearchMatch = false

    $scope.searchOpts = {
      search: () ->
        $scope.search($scope.searchKey, $scope.searchOpts.val)
      showSearch: true
    }

    # Category for instance action
    $scope.singleSelectedItem = {}

    # Variates for dataTable
    # --start--

    # For checkbox select
    $scope.AllSelectedItems = false
    $scope.NoSelectedItems = true

    $scope.pagingOptions = {
      pageSize: 15
      currentPage: 1
    }
    $scope.filterOptions =
      filterText: '',
      useExternalFilter: true

    $scope.volumes = []

    $scope.volumesOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      pageMax: 5
    }

    $scope.judgeStatus = (item) ->
      if item.status in $scope.labileStatus
        item.labileStatus = 'unknwon'
      else if item.status in $scope.abnormalStatus
        item.labileStatus = 'abnormal'
      else
        item.labileStatus = 'active'

      item.status = _(item.status)

    # Function for get paded instances and assign class for
    # element by status
    setPagingData = (pagedData, total) ->
      $scope.volumes = pagedData
      # Compute the total pages
      $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
      $scope.volumesOpts.data = $scope.volumes
      $scope.volumesOpts.pageCounts = $scope.pageCounts

      for item in pagedData
        $scope.judgeStatus item

      if !$scope.$$phase
        $scope.$apply()

    # --End--

    # Functions for handle event from action

    $scope.selectedItems = []
    $scope.selectChange = () ->
      if $scope.selectedItems.length == 1
        $scope.NoSelectedItems = false
        $scope.batchActionEnableClass = 'btn-enable'
      else if $scope.selectedItems.length > 1
        $scope.NoSelectedItems = false
        $scope.batchActionEnableClass = 'btn-enable'
      else
        $scope.NoSelectedItems = true
        $scope.batchActionEnableClass = 'btn-disable'
        $scope.singleSelectedItem = {}

    volumeGet = ($http, $window, $q, volumeId, callback) ->
      $http.get "#{serverUrl}/volumes/#{volumeId}"
        .success (volume) ->
          callback volume
        .error (err) ->
          # TODO(Lixipeng): handle get volume error.
          console.log "Failed to get volume detail: %s", err

    # Functions about interaction with volume
    # --Start--

    # periodic get volume data which status is 'processing'
    $scope.labileVolumeQueue = {}
    getLabileData = (volumeId) ->
      if $scope.labileVolumeQueue[volumeId]
        return
      else
        $running $scope, volumeId
        $scope.labileVolumeQueue[volumeId] = true

      update = () ->
        volumeGet $http, $window, $q, volumeId, (volume) ->
          if volume
            if volume.status not in $scope.labileStatus
              $interval.cancel(freshData)
              $running $scope, volumeId

            angular.forEach $scope.volumes, (row, index) ->
              if row.id == volume.id
                volume.pureStatus = volume.status
                $scope.judgeStatus volume
                volume.isSelected = $scope.volumes[index].isSelected
                volume.project = $scope.volumes[index].project
                volume.attachments = JSON.parse volume.attachments
                volume.attachments = $scope.volumes[index].attachments
                volume.volume_type = $scope.volumes[index].volume_type
                volume.size = Number(volume.size)
                $scope.volumes[index] = volume
                if volume.status == 'DELETED'
                  $scope.volumes.splice(index, 1)
                  $deleted $scope, volumeId
          else
            $interval.cancel(freshData)
            $deleted $scope, volumeId
            angular.forEach $scope.volumes, (row, index) ->
              if row.id == volumeId
                $scope.volumes.splice(index, 1)

      freshData = $interval(update, 5000)
      update()

      if (!$.intervalList)
        $.intervalList = []
      $.intervalList.push(freshData)

    listDetailedVolumes = ($http, $window, $q, dataQueryOpts, callback) ->
      if dataQueryOpts.search == true
        volumesURL = "#{serverUrl}/volumes/search"
      else
        volumesURL = "#{serverUrl}/volumes"
      $http.get(volumesURL, {
        params: dataQueryOpts
      }).success (res) ->
        if not res
          res =
            data: []
            total: 0
        servers = []
        projects = []
        for volume in res.data
          volume.pureStatus = volume.status
          volume.size = Number(volume.size)
          if volume.tenant_id not in projects
            projects.push volume.tenant_id
          att = JSON.parse volume.attachments
          if not att.length
            volume.attachments = ''
          else
            volume.attachments = att[0].server_id
            servers.push att[0].server_id
          if not volume.display_name || volume.display_name == "null"
            volume.display_name = volume.id

        projectHttp = $http.get("#{serverUrl}/projects/query", {
          params:
            ids: JSON.stringify projects
            fields: '["name"]'
        })
        serverHttp = $http.get("#{serverUrl}/servers/query", {
          params:
            ids: JSON.stringify servers
            fields: '["name"]'
        })
        $q.all([
         projectHttp,
         serverHttp
        ])
          .then (rs) ->
            projects = rs[0].data
            servers = rs[1].data
            for volume in res.data
              if not volume.volume_type || volume.volume_type == "None"
                volume.volume_type = _("None")
              if volume.attachments
                if servers[volume.attachments]
                  volume.attachName = servers[volume.attachments].name
              if projects[volume.tenant_id]
                volume.project = projects[volume.tenant_id].name
              else
                volume.project = volume.tenant_id
            callback res.data, res.total
          , (err) ->
            console.log err, "Failed to get projects/servers name"

    # Function for async list instances
    getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        dataQueryOpts =
          all_tenants: true
          limit_from: parseInt(pageSize) * parseInt(currentPage)
          limit_to: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize)
        if $scope.searched
          dataQueryOpts.search = true
          dataQueryOpts.searchKey = $scope.searchKey
          dataQueryOpts.searchValue = $scope.searchOpts.val
          dataQueryOpts.require_detail = true
        listDetailedVolumes $http, $window, $q, dataQueryOpts,
        (volumes, total) ->
          for volume in volumes
            type = volume['purpose']
            volume.purposeDisplay = volType[type]
          setPagingData(volumes, total)
          (callback && typeof(callback) == "function") && \
          callback(volumes)
      , 300)

    getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    # Callback for instance list after paging change
    watchCallback = (newVal, oldVal) ->
      $scope.volumesOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage

    $scope.$watch('pagingOptions', watchCallback, true)

    # Callback after instance list change
    volumeCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for volume in newVal
          if $scope.selectedItemId
            if volume.id == $scope.selectedItemId
              volume.isSelected = true
              $scope.selectedItemId = undefined
          if volume.pureStatus in $scope.labileStatus
            getLabileData(volume.id)
          if volume.isSelected == true
            selectedItems.push volume
        $scope.selectedItems = selectedItems

    $scope.$watch('volumes', volumeCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    volumeDelete = ($http, $window, volumeId, callback) ->
      $http.delete("#{serverUrl}/volumes/#{volumeId}")
        .success (rs) ->
          callback(200)
        .error (err) ->
          callback(err.status, err.message, volumeId)

    # FIXME(Li Xiepng): We should add an service to handle
    # volume deleting, `_do_delete_volume`, `_deleteVolume`
    # method are the same in project/controllers/index.coffee
    _do_delete_volume = (item, index) ->
      volumeId = item.id
      name = item.display_name || volumeId
      message =
        object: "volume-#{volumeId}"
        priority: 'success'
        loading: 'true'
        content: _(["Volume %s is %s ...", name, _("deleting")])
      $gossipService.receiveMessage message
      volumeDelete $http, $window, volumeId, (response, msg, id) ->
        if response == 200
          angular.forEach $scope.volumes, (row, index) ->
            if row.id == volumeId
              $scope.volumes[index].pureStatus = 'deleting'
              $scope.volumes[index].status = 'deleting'
              $scope.judgeStatus $scope.volumes[index]
              return false
          getLabileData(volumeId)
        else
          reg = /^Invalid volume: Volume still has \d dependent snapshots$/
          if reg.test(msg)
            message =
              object: "volume-#{id}"
              priority: 'error'
              content: _("Snapshots still depent on volume: ") + name
            $gossipService.receiveMessage message

    _deleteVolume = (item, index) ->
      volumeId = item.id
      name = item.display_name || volumeId
      if item.attachments.id
        toastr.options.closeButton = true
        msg = item.display_name +
              _(" has attached to instance ") +
              item.attachments.name
        toastr.warning msg
        return false
      # If it is not an image-used volume, delete directly.
      if item.purpose != 'image' and item.purpose != 'system backup'
        _do_delete_volume(item, index)
        return true
      # If it is an image-used volume, delete directly.
      # Get image id from metadata and find whether this
      # image is exist, if exist warning and not delete
      # this volume, otherwise delete this volume when
      # Get an 404 error with http request.
      if item.purpose == 'image'
        meta = item.metadata
      else if item.purpose == 'system backup'
        meta = item.volume_image_metadata
      try
        meta = JSON.parse meta
      catch e
        meta = {}
      image = meta.glance_image_id or meta.image_id
      if not image
        _do_delete_volume(item, index)
        return true
      $http.get "#{serverUrl}/images/#{image}"
        .success (img) ->
          if not img
            _do_delete_volume(item, index)
            return false
          toastr.warning _ ["Volume %s is used to store image data.", item.display_name]
        .error (err, status) ->
          if (err and err.status == 404) or status == 404
            _do_delete_volume(item, index)

    # Delete selected servers
    $scope.deleteVolume = () ->
      angular.forEach $scope.selectedItems, _deleteVolume

    $selectedItem $scope, 'volumes'

    $scope.refresResource = (resource) ->
      $scope.volumesOpts.data = null
      getPagedDataAsync($scope.pagingOptions.pageSize,
                        $scope.pagingOptions.currentPage)

    $scope.$on('update', (event, detail) ->
      for volume in $scope.volumes
        if volume.id == detail.id
          volume.display_name = detail.display_name
          break
    )

  .controller 'admin.volume.SnapshotTabCtr', ($scope, $http, $window,
  $q, $state, $interval, $selectedItem, $clearInterval, $gossipService) ->
    $scope.$on '$gossipService.volume_snapshot', (event, meta) ->
      id = meta.payload.id
      if $scope.snapshots
        counter = 0
        len = $scope.snapshots.length
        loop
          break if counter >= len
          if $scope.snapshots[counter].id == id
            break
          counter += 1
        if meta.event == 'volume.snapshot.delete.end'
          $scope.snapshots.splice counter, 1
        if !$scope.$$phase
          $scope.$apply()
    serverUrl = $window.$CROSS.settings.serverURL
    $scope.note =
      buttonGroup:
        delete: _("Delete")
        refresh: _("Refresh")

    # Category for instance action
    $scope.batchActionEnableClass = 'btn-disable'

    # For sort at table header
    $scope.sort = {
      reverse: false
    }

    # For tabler footer and pagination or filter
    $scope.showFooter = false

    # Category for instance status
    $scope.labileStatus = [
      'creating'
      'error_deleting'
      'deleting'
    ]
    $scope.abnormalStatus = [
      'error'
    ]

    $scope.columnDefs = [
      {
        field: "display_name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText" data-placement="top" title="{{item.display_name}}" ng-bind="item.display_name"></div>'
      }
      {
        field: "size"
        displayName: _("Size(GB)")
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
      {
        field: "volume"
        displayName: _("Volume")
        cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.volume}}"><a ui-sref="admin.volume.volumeId.overview({ volumeId:item.volume_id,tab:item.tab} )" ng-bind="item.volume"></a></div>'
      }
      {
        field: "project"
        displayName: _("Project")
        cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.project}}"><a ui-sref="admin.project.projId.overview({ projId:item.tenant_id })" ng-bind="item.project"></a></div>'
      }
      {
        field: "status",
        displayName: _("Status"),
        cellTemplate: '<div class="ngCellText status" ng-class="item.labileStatus"><i data-toggle="tooltip" data-placement="top" title="{{item.status}}"></i>{{item.status}}</div>'
      }
    ]
    # --End--
    # Category for instance action
    $scope.singleSelectedItem = {}

    # Variates for dataTable
    # --start--

    # For checkbox select
    $scope.AllSelectedItems = false
    $scope.NoSelectedItems = true

    $scope.pagingOptions = {
      pageSize: 15
      currentPage: 1
    }
    $scope.filterOptions =
      filterText: '',
      useExternalFilter: true

    $scope.snapshots = []

    $scope.snapshotsOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      pageMax: 5
    }

    $scope.judgeStatus = (item) ->
      if item.status in $scope.labileStatus
        item.labileStatus = 'unknwon'
      else if item.status in $scope.abnormalStatus
        item.labileStatus = 'abnormal'
      else
        item.labileStatus = 'active'

      item.status = _(item.status)

    # Function for get paded instances and assign class for
    # element by status
    setPagingData = (pagedData, total) ->
      $scope.snapshots = pagedData
      # Compute the total pages
      $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
      $scope.snapshotsOpts.data = $scope.snapshots
      $scope.snapshotsOpts.pageCounts = $scope.pageCounts

      for item in pagedData
        $scope.judgeStatus item

      if !$scope.$$phase
        $scope.$apply()

    # --End--

    # Functions for handle event from action

    $scope.selectedItems = []
    # TODO(ZhengYue): Add batch action enable/disable judge by status
    $scope.snapshotSelectChange = () ->
      if $scope.selectedItems.length == 1
        $scope.NoSelectedItems = false
        $scope.batchActionEnableClass = 'btn-enable'
      else if $scope.selectedItems.length > 1
        $scope.NoSelectedItems = false
        $scope.batchActionEnableClass = 'btn-enable'
        $state.go 'adminvolume'
      else
        $scope.NoSelectedItems = true
        $scope.batchActionEnableClass = 'btn-disable'
        $scope.singleSelectedItem = {}
        $state.go 'admin.volume'

    # Functions about interaction with volume
    # --Start--

    listDetailedSnapshot = ($http, $window, $q, dataQueryOpts, callback) ->
      $http.get("#{serverUrl}/cinder/snapshots?all_tenants=True").success (snapshots) ->
        if not snapshots
          res =
            data: []
            total: 0
        else

          res =
            data: snapshots
            total: snapshots.length
        volumes = []
        projects = []
        for snap in res.data
          snap.pureStatus = snap.status
          volumes.push snap['volume_id']
          tenant_id = snap['os-extended-snapshot-attributes:project_id']
          snap.tenant_id = tenant_id
          projects.push tenant_id
        volumeHttp = $http.get("#{serverUrl}/volumes/query", {
          params:
            ids: JSON.stringify volumes
            fields: '["display_name"]'
        })
        projectHttp = $http.get("#{serverUrl}/projects/query", {
          params:
            ids: JSON.stringify projects
            fields: '["name"]'
        })
        $q.all([
         volumeHttp,
         projectHttp
        ])
          .then (rs) ->
            volumes = rs[0].data
            projects = rs[1].data
            for snap in res.data
              if volumes[snap.volume_id]
                snap.volume = volumes[snap.volume_id].display_name
                snap.project = projects[snap.tenant_id].name
            callback res.data, res.total
          , (err) ->
            console.log err, "Failed to get projects/servers name"

    # Function for async list instances
    getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        dataQueryOpts =
          limit_from: parseInt(pageSize) * parseInt(currentPage)
          limit_to: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize)
        listDetailedSnapshot $http, $window, $q, dataQueryOpts,
        (snapshots, total) ->
          for snapshot in snapshots
            name = /^snapshot for (.*)$/g.exec(snapshot.display_name)
            snapshot.display_name = name[1] if name
          setPagingData(snapshots, total)
          (callback && typeof(callback) == "function") && callback()
      , 300)

    getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    snapshotGet = ($http, $window, $q, snapshotId, callback) ->
      $http.get "#{serverUrl}/ciner/snapshots/#{snapshotId}"
        .success (snapshot) ->
          callback snapshot
        .error (err) ->
          callback undefined
          # TODO(Lixipeng): handle get volume error.
          console.log "Failed to get volume detail: %s", err

    # Functions about interaction with volume
    # --Start--

    # periodic get volume data which status is 'processing'
    getLabileData = (snapshotId) ->
      freshData = $interval(() ->
        snapshotGet $http, $window, $q, snapshotId, (snapshot) ->
          if snapshot
            if snapshot.pureStatus not in $scope.labileStatus
              $interval.cancel(freshData)

            angular.forEach $scope.snapshots, (row, index) ->
              if row.id == snapshot.id
                snapshot.pureStatus = snapshot.status
                $scope.judgeStatus snapshot
                snapshot.volume = $scope.snapshots[index].volume
                $scope.snapshot[index] = snapshot
                if snapshot.status == 'DELETED'
                  $scope.snapshots.splice(index, 1)
          else
            $interval.cancel(freshData)
            angular.forEach $scope.snapshots, (row, index) ->
              if row.id == snapshotId
                $scope.snapshots.splice(index, 1)
                return false
      , 5000)

    # Callback for instance list after paging change
    watchCallback = (newVal, oldVal) ->
      $scope.snapshotsOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage,
                                 loadCallback

    $scope.$watch('pagingOptions', watchCallback, true)

    # Callback after instance list change
    snapshotCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for snap in newVal
          if $scope.selectedItemId
            if snap.id == $scope.selectedItemId
              snap.isSelected = true
              $scope.selectedItemId = undefined
          if snap.pureStatus in $scope.labileStatus
            getLabileData(snap.id)
          if snap.isSelected == true
            selectedItems.push snap
        $scope.selectedItems = selectedItems

    $scope.$watch('snapshots', snapshotCallback, true)

    $scope.$watch('selectedItems', $scope.snapshotSelectChange, true)

    snapshotDelete = ($http, $window, snapshotId, callback) ->
      $http.delete("#{serverUrl}/cinder/snapshots/#{snapshotId}")
        .success (rs) ->
          callback(200)
        .error (err) ->
          callback(err.status)

    # Delete selected servers
    $scope.deleteSnapshot = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        snapshotId = item.id
        name = item.display_name || snapshotId
        message =
          object: "volume_snapshot-#{snapshotId}"
          priority: 'success'
          loading: 'true'
          content: _(["Volume snapshot %s is %s", name, _("deleting")])
        $gossipService.receiveMessage message
        snapshotDelete $http, $window, snapshotId, (response) ->
          if response == 200
            angular.forEach $scope.snapshots, (row, index) ->
              if row.id == snapshotId
                $scope.snapshots[index].status = 'deleting'
                $scope.judgeStatus $scope.snapshots[index]
                return false
            getLabileData(snapshotId)

    $selectedItem $scope, 'snapshots'

    $scope.refresResource = (resource) ->
      $scope.snapshotsOpts.data = null
      getPagedDataAsync($scope.pagingOptions.pageSize,
                        $scope.pagingOptions.currentPage)

    $clearInterval $scope, $interval
