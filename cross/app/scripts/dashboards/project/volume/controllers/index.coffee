'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.project.volume')
  .controller 'project.volume.VolumeCtr', ($scope, $http, $window, $q,
  $state, $stateParams, $interval) ->
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
      $state.go "project.volume", params, {inherit: false}

  .controller 'project.volume.VolumeTabCtr', ($scope, $http, $window,
  $q, $state, $interval, $selectedItem, $running, $deleted,
  $clearInterval, $gossipService) ->
    serverUrl = $window.$CROSS.settings.serverURL
    $scope.$on '$gossipService.volume', (event, meta) ->
      id = meta.payload.id
      $http.get("#{serverUrl}/volumes/#{id}").success (volume) ->
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
          try
            attachments = JSON.parse volume.attachments
          catch e
            attachments = []
          if attachments.length
            ids = []
            ids.push attachments[0].server_id
            params =
              params:
                ids: JSON.stringify ids
                fields: '["name"]'
            $http.get("#{serverUrl}/servers/query", params).success (vDict) ->
              if vDict and vDict[ids[0]]
                volume.attachments =
                  name: vDict[ids[0]].name
                  id  : ids[0]
          volume.pureStatus = volume.status
          if $scope.judgeStatus
            $scope.judgeStatus volume
          $scope.volumes[counter] = volume

          if !$scope.$$phase
            $scope.$apply()

    # handle vmware instance volume attach condition
    unableStatus = []
    hypervisor_type = $CROSS.settings.hypervisor_type
    if hypervisor_type \
    and hypervisor_type.toLocaleLowerCase() == 'vmware'
      unableStatus.push 'ACTIVE'

    $scope.note =
      buttonGroup:
        snapshot: _("Snapshot")
        create: _("Create")
        delete: _("Delete")
        attach: _("Attach")
        detach: _("Detach")
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
        cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.display_name}}"><a ui-sref="project.volume.volumeId.overview({ volumeId:item.id })" ng-bind="item.display_name"></a></div>'
      }
      {
        field: "host"
        displayName: _("Host")
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]" data-toggle="tooltip" data-placement="top" title="{{item.host}}"></div>'
      }
      {
        field: "size"
        displayName: _("Size(GB)")
        cellTemplate: '<div ng-bind="item[col.field] | number"></div>'
      }
      {
        field: "purposeDisplay"
        displayName: _("Type")
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
      {
        field: "attachments"
        displayName: _("Attach To")
        cellTemplate: '<div class="ngCellText" ng-if="item[col.field].name">\
                       <a ui-sref="project.instance.instanceId.overview({ instanceId:item[col.field].id })"\
                        ng-bind="item[col.field].name?item[col.field].name:\'' + notAttach + '\'"></a></div>\
                       <div class="ngCellText" ng-if="!item[col.field].name" \
                        ng-bind="item[col.field].name?item[col.field].name:\'' + notAttach + '\'"></div>'
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
    $scope.singleEnableClass = 'btn-disable'
    $scope.selectChange = () ->
      selectedItems = $scope.selectedItems
      if selectedItems.length == 1
        $scope.NoSelectedItems = false
        $scope.batchActionEnableClass = 'btn-enable'
        $scope.singleSelectedItem = selectedItems[0]
        $scope.singleEnableClass = 'btn-enable'
      else if selectedItems.length > 1
        $scope.NoSelectedItems = false
        $scope.batchActionEnableClass = 'btn-enable'
        $scope.singleEnableClass = 'btn-disable'
      else
        $scope.NoSelectedItems = true
        $scope.batchActionEnableClass = 'btn-disable'
        $scope.singleSelectedItem = {}
        $scope.singleEnableClass = 'btn-disable'
      if selectedItems.length == 1
        if selectedItems[0].attachments.id\
        and selectedItems[0].attachments.serverStatus not in unableStatus
          $scope.canAttach = false
          $scope.canDetach = true
          if selectedItems[0].bootable == 'true'
            $scope.canDetach = false
          return true
        else if selectedItems[0].bootable == 'true'
          $scope.canDetach = false
          $scope.canAttach = false
          return true
        else if selectedItems[0].purpose != 'data'\
        and selectedItems[0].purpose != 'data backup'
          $scope.canDetach = false
          $scope.canAttach = false
          $scope.backupEabled = false
          return true
        if selectedItems[0].pureStatus == 'available'
          $scope.canAttach = true
          $scope.backupEabled = true
        $scope.canDetach = false
      else
        $scope.canDetach = false
        $scope.canAttach = false
        $scope.backupEabled = false

    volumeGet = ($http, $window, $q, volumeId, callback) ->
      $http.get "#{serverUrl}/volumes/#{volumeId}"
        .success (volume) ->
          callback volume
        .error (err) ->
          # TODO(Lixipeng): handle get volume error.
          callback undefined

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
              delete $scope.labileVolumeQueue[volumeId]

            angular.forEach $scope.volumes, (row, index) ->
              if row.id == volume.id
                volume.pureStatus = volume.status
                $scope.judgeStatus volume
                volume.isSelected = $scope.volumes[index].isSelected
                volume.project = $scope.volumes[index].project
                volume.attachments = JSON.parse volume.attachments
                volume.attachments = $scope.volumes[index].attachments
                volume.volume_type = $scope.volumes[index].volume_type
                volume.host = volume['os-vol-host-attr:host']
                $scope.volumes[index] = volume
                if volume.status == 'DELETED'
                  $scope.volumes.splice(index, 1)
                  $deleted $scope, volumeId
                  delete $scope.labileVolumeQueue[volumeId]
          else
            $interval.cancel(freshData)
            $deleted $scope, volumeId
            delete $scope.labileVolumeQueue[volumeId]
            angular.forEach $scope.volumes, (row, index) ->
              if row.id == volumeId
                $scope.volumes.splice(index, 1)

      freshData = $interval(update, 5000)
      update()

      if (!$.intervalList)
        $.intervalList = []
      $.intervalList.push(freshData)

    listDetailedVolumes = ($http, $window, $q, dataQueryOpts, callback) ->
      $http.get("#{serverUrl}/volumes", {
        params: dataQueryOpts
      }).success (res) ->
        if not res
          res =
            data: []
            total: 0
        servers = []
        for volume in res.data
          volume.pureStatus = volume.status
          att = JSON.parse volume.attachments
          if not att.length
            volume.attachments = {}
          else
            volume.attachments =
              id: att[0].server_id
            servers.push att[0].server_id
          if not volume.display_name || volume.display_name == "null"
            volume.display_name = volume.id
          volume.host = volume['os-vol-host-attr:host']

        serverHttp = $http.get("#{serverUrl}/servers/query", {
          params:
            ids: JSON.stringify servers
            fields: '["name", "status"]'
        })
        $q.all([
         serverHttp
        ])
          .then (rs) ->
            servers = rs[0].data
            for volume in res.data
              if not volume.volume_type || volume.volume_type == "None"
                volume.volume_type = _("None")
              if volume.attachments.id
                if servers[volume.attachments.id]
                  volume.attachments.serverStatus = servers[volume.attachments.id].status
                  volume.attachments.name = servers[volume.attachments.id].name
            callback res.data, res.total
          , (err) ->
            toastr.error _("Failed to get projects/servers name")

    # Function for async list instances
    getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        dataQueryOpts =
          limit_from: parseInt(pageSize) * parseInt(currentPage)
          limit_to: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize)
        listDetailedVolumes $http, $window, $q, dataQueryOpts,
        (volumes, total) ->
          for volume in volumes
            type = volume['purpose']
            volume.purposeDisplay = volType[type]
          setPagingData(volumes, total)
          (callback && typeof(callback) == "function") && callback()
      , 300)

    getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

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

    itemDetach = (itemId, serverId, callback) ->
      serverUrl = $CROSS.settings.serverURL
      $http.delete "#{serverUrl}/servers/#{serverId}/os-volume_attachments/#{itemId}"
        .success ->
          callback 200
        .error (err, status) ->
          callback status

    # handle detaching volume.
    $scope.detachVolume = ->
      selectedItems = $scope.selectedItems
      if not selectedItems or not selectedItems.length
        return
      item = $scope.selectedItems[0]
      volumeId = item.id
      name = item.display_name || volumeId
      serverId = item.attachments.id
      serName = item.attachments.name
      message =
        object: "instance-#{serverId}"
        priority: 'success'
        loading: 'true'
        content: _(["Instance %s is %s %s", serName, _("detaching"), name])
      $gossipService.receiveMessage message
      itemDetach volumeId, serverId, (response) ->
        if response != 200
          return false

        angular.forEach $scope.items, (row, index) ->
          if row.id == volumeId
            $scope.items[index].status = 'detaching'
            $scope.judgeStatus $scope.items[index]
            return false
        getLabileData volumeId

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

    # Delete selected volumes
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

  .controller 'project.volume.SnapshotTabCtr', ($scope, $http, $window,  $q, $running, $deleted,
                    $state, $interval, $clearInterval, $selectedItem, $gossipService) ->
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
        if meta.event == 'volume.snapshot.create.end'
          snapshot = $scope.snapshots[counter]
          snapshot.status = 'active'
          if $scope.judgeStatus
            $scope.judgeStatus snapshot
          $scope.snapshots[counter] = snapshot
        else if meta.event == 'volume.snapshot.delete.end'
          $scope.snapshots.splice counter, 1
        if !$scope.$$phase
          $scope.$apply()

    serverUrl = $window.$CROSS.settings.serverURL
    $scope.note =
      snapshot: _("volume snapshot")
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
        field: "name",
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
        cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.volume}}"><a ui-sref="project.volume.volumeId.overview({ volumeId:item.volume_id, tab:item.tab })" ng-bind="item.volume"></a></div>'
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
        $state.go 'project.volume'
      else
        $scope.NoSelectedItems = true
        $scope.batchActionEnableClass = 'btn-disable'
        $scope.singleSelectedItem = {}
        $state.go 'project.volume'

    # Functions about interaction with volume
    # --Start--

    listDetailedSnapshot = ($http, $window, $q, dataQueryOpts, callback) ->
      $http.get("#{serverUrl}/cinder/snapshots").success (snapshots) ->
        if not snapshots
          res =
            data: []
            total: 0
        else
          res =
            data: snapshots
            total: snapshots.length
        volumes = []
        for snap in res.data
          snap.pureStatus = snap.status
          volumes.push snap['volume_id']
        volumeHttp = $http.get("#{serverUrl}/volumes/query", {
          params:
            ids: JSON.stringify volumes
            fields: '["display_name"]'
        })
        $q.all([
         volumeHttp
        ])
          .then (rs) ->
            volumes = rs[0].data
            for snap in res.data
              if volumes[snap.volume_id]
                snap.volume = volumes[snap.volume_id].display_name
            callback res.data, res.total
          , (err) ->
            toastr.error _("Failed to get projects/servers name")

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
      $http.get "#{serverUrl}/cinder/snapshots/#{snapshotId}"
        .success (snapshot) ->
          callback snapshot
        .error (err) ->
          callback undefined
          # TODO(Lixipeng): handle get volume error.

    # Functions about interaction with volume
    # --Start--

    # periodic get volume data which status is 'processing'
    $scope.labileSnapshotQueue = {}
    getLabileData = (snapshotId) ->
      if $scope.labileSnapshotQueue[snapshotId]
        return
      else
        $running $scope, snapshotId
        $scope.labileSnapshotQueue[snapshotId] = true
      update = () ->
        snapshotGet $http, $window, $q, snapshotId, (snapshot) ->
          if snapshot
            if snapshot.status not in $scope.labileStatus
              $interval.cancel(freshData)
              $running $scope, snapshotId
              delete $scope.labileSnapshotQueue[snapshotId]

            angular.forEach $scope.snapshots, (row, index) ->
              if row.id == snapshot.id
                snapshot.pureStatus = snapshot.status
                $scope.judgeStatus snapshot
                snapshot.volume = $scope.snapshots[index].volume
                $scope.snapshots[index] = snapshot
                if snapshot.status == 'DELETED'
                  $scope.snapshots.splice(index, 1)
                  $deleted $scope, snapshotId
                  delete $scope.labileSnapshotQueue[snapshotId]
          else
            $interval.cancel(freshData)
            $deleted $scope, snapshotId
            delete $scope.labileSnapshotQueue[snapshotId]
            angular.forEach $scope.snapshots, (row, index) ->
              if row.id == snapshotId
                $scope.snapshots.splice(index, 1)

      freshData = $interval(update, 5000)
      update()

      if (!$.intervalList)
        $.intervalList = []
      $.intervalList.push(freshData)

    # Callback for instance list after paging change
    watchCallback = (newVal, oldVal) ->
      tbody = angular.element('tbody.cross-data-table-body')
      tfoot = angular.element('tfoot.cross-data-table-foot')
      tbody.hide()
      loadCallback = () ->
        tbody.show()
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
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
          # TODO(ZhengYue): Add some tips for success or failed
          if response == 200
            angular.forEach $scope.snapshots, (row, index) ->
              if row.id == snapshotId
                $scope.snapshots[index].status = 'deleting'
                $scope.snapshots[index].pureStatus = 'deleting'
                $scope.judgeStatus $scope.snapshots[index]
                return false
            getLabileData(snapshotId)

    $selectedItem $scope, 'snapshots'

    $scope.refresResource = (resource) ->
      $scope.snapshotsOpts.data = null
      getPagedDataAsync($scope.pagingOptions.pageSize,
                        $scope.pagingOptions.currentPage)

    $clearInterval $scope, $interval
