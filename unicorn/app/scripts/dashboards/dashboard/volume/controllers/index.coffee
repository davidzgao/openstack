'use strict'

###*
 # @ngdoc function
 # @name Unicorn.dashboard.instance:VolumeCtr
 # @description
 # # VolumeCtr
 # Controller of the Unicorn
###
angular.module("Unicorn.dashboard.volume")
  .controller "dashboard.volume.VolumeCtr", ($scope, $http, $interval,
  $q, $window, $state, $stateParams, $gossipService, $dataLoader, tryApply) ->
    # Initial note.
    $scope.note =
      volume: _("volume")
      buttonGroup:
        detach: _("Detach")
        attachVolume: _("Attach")
        applyVolume: _("Apply volume")
        delete: _("Delete")
        refresh: _("Refresh")

    (new tableView()).init($scope, {
      $http: $http
      $q: $q
      $window: $window
      $interval: $interval
      $state: $state
      $stateParams: $stateParams
      $gossipService: $gossipService
      $dataLoader: $dataLoader
      $tryApply: tryApply
    })

    $scope.itemLinkAction = (link, enable) ->
      if enable != "enabled"
        return false
      if $scope.selectedItems.length != 1
        return
      $state.go link, {volId: $scope.selectedItems[0].id}

    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      searchOpts:
        showSearch: true
        searchKey: 'name'
        searchAction: $scope.search
      buttons: [
        {
          type: 'single'
          tag: 'button'
          name: 'create'
          verbose: $scope.note.buttonGroup.applyVolume
          enable: true
          action: $scope.tryApply
          needConfirm: true
        }
        {
          type: 'link'
          tag: 'a'
          name: 'attach'
          verbose: $scope.note.buttonGroup.attachVolume
          ngClass: 'batchActionEnableClass'
          action: $scope.itemLinkAction
          link: 'dashboard.volume.volId.attach'
          enable: false
          confirm: _ 'Attach Volume'
          needConfirm: true
          restrict: {
            batch: true
            status: 'available'
          }
        }
        {
          type: 'single'
          tag: 'button'
          name: 'detach'
          verbose: $scope.note.buttonGroup.detach
          ngClass: 'batchActionEnableClass'
          action: $scope.detachVolume
          enable: false
          confirm: _ 'Detach'
          restrict: {
            batch: true
            status: 'in-use'
          }
        }
        {
          tag: 'button'
          name: 'delete'
          verbose: $scope.note.buttonGroup.delete
          enable: false
          type: 'action'
          ngClass: 'batchActionEnableClass'
          action: $scope.deleteVolume
          needConfirm: true
          confirm: _ 'Delete'
          restrict: {
            batch: true
          }
        }
      ]
    }

class tableView extends $unicorn.TableView
  @notAttach: _("Not attach")
  slug: 'volume'
  labileStatus: [
    'creating'
    'error_deleting'
    'deleting'
    'attaching'
    'detaching'
    'downloading'
  ]
  abnormalStatus: [
    'error'
  ]
  columnDefs: [
    {
      field: "name",
      displayName: _("Name"),
      cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.display_name}}"><a ui-sref="dashboard.volume.volumeId.overview({ volumeId:item.id })" ng-bind="item.display_name"></a></div>'
    }
    {
      field: "host"
      displayName: _("Host")
      cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]" data-toggle="tooltip" data-placement="top" title="{{item.host}}"></div>'
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
      field: "attachments"
      displayName: _("Attach To")
      cellTemplate: "<div ng-bind=\"item[col.field]?item[col.field].name:'#{tableView.notAttach}'\"></div>"
    }
    {
      field: "status",
      displayName: _("Status"),
      cellTemplate: '<div class="ngCellText status" ng-class="item.labileStatus"><i data-toggle="tooltip" data-placement="top" title="{{item.status}}"></i>{{item.STATUS}}</div>'
    }
  ]
  federatorType =
    {
      field: "volume_type"
      displayName: _("Performance Type")
      cellTemplate: '<div ng-bind="item[col.field]"></div>'
    }
  if $UNICORN.settings.useFederator
    $scope.columnDefs.splice 3, 0, federatorType

  listData: ($scope, options, dataQueryOpts, callback) ->
    volType =
      'data': _ "Data Volume"
      'data backup': _ "Data Volume Backup"
      'system': _ "System Volume"
      'system backup': _ "System Volume Backup"
      'image': _ "Image Volume"
    serverUrl = $UNICORN.settings.serverURL
    $http = options.$http
    $q = options.$q
    if dataQueryOpts.dataFrom != undefined
      dataQueryOpts.limit_from = dataQueryOpts.dataFrom
      delete dataQueryOpts.dataFrom
    if dataQueryOpts.dataTo != undefined
      dataQueryOpts.limit_to = dataQueryOpts.dataTo
      delete dataQueryOpts.dataTo
    volumeURL = "#{serverUrl}/volumes"
    if dataQueryOpts.search
      volumeURL = "#{volumeURL}/search"
    $http.get(volumeURL, {
      params: dataQueryOpts
    }).success (res) ->
      if not res
        res =
          data: []
          total: 0
      servers = []
      for volume in res.data
        volume.status = volume.status
        att = JSON.parse volume.attachments
        if not att.length
          volume.attachments = ''
        else
          volume.attachments = att[0].server_id
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
            type = volume['purpose']
            volume.purposeDisplay = volType[type]
            if volume.attachments
              if servers[volume.attachments]
                volume.attachments = {
                  serverStatus: servers[volume.attachments].status
                  name: servers[volume.attachments].name
                  id: volume.attachments
                }
          callback res.data, res.total
        , (err) ->
          callback [], 0
          toastr.error _("Failed to get projects/servers name")
    return true

  itemGet: (itemId, options, callback) ->
    $http = options.$http
    serverUrl = $UNICORN.settings.serverURL
    $http.get "#{serverUrl}/volumes/#{itemId}"
      .success (volume) ->
        callback volume
      .error (err, status) ->
        callback undefined

  itemDelete: ($scope, itemId, options, callback) ->
    $http = options.$http
    $window = options.$window
    serverUrl = $UNICORN.settings.serverURL
    $http.delete "#{serverUrl}/volumes/#{itemId}"
      .success ->
        callback 200
      .error (err, status) ->
        callback status, err.message

  itemDetach: ($scope, itemId, serverId, options, callback) ->
    $http = options.$http
    $window = options.$window
    serverUrl = $UNICORN.settings.serverURL
    $http.delete "#{serverUrl}/servers/#{serverId}/os-volume_attachments/#{itemId}"
      .success ->
        callback 200
      .error (err, status) ->
        callback status

  initialAction: ($scope, options) ->
    super $scope, options
    obj = options.$this
    $scope.$on '$gossipService.volume', (event, meta) ->
      $http = options.$http
      serverUrl = $UNICORN.settings.serverURL
      $q = options.$q
      id = meta.payload.id
      $http.get("#{serverUrl}/volumes/#{id}").success (volume) ->
        if $scope.items
          counter = 0
          len = $scope.items.length
          loop
            break if counter >= len
            if $scope.items[counter].id == id
              break
            counter += 1
          if not volume
            $scope.items.splice counter, 1
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
          if obj.judgeStatus
            obj.judgeStatus $scope, volume, options
          $scope.items[counter] = volume

    # search volumes by name.
    $scope.search = (key, value) ->
      pageSize = obj.pagingOptions.pageSize
      currentPage = 0
      searchVal = value
      if searchVal == undefined
        searchVal = ''
      dataQueryOpts =
        dataFrom: parseInt(pageSize) * parseInt(currentPage)
        dataTo: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize)
        search: true
        searchKey: 'display_name'
        searchValue: searchVal
        require_detail: true
        tenant_id: $UNICORN.person.project.id
      obj.listData $scope, options, dataQueryOpts,
      (items, total) ->
        obj.setPagingData items, total, $scope, options


    # handle delete action.
    $scope.deleteVolume = ->
      obj.action $scope, options, (item, index) ->
        volumeId = item.id
        name = item.display_name || volumeId
        if item.attachments
          msg = item.display_name +
                _(" has attached to instance ") +
                item.attachments.name
          toastr.warning msg
          return false
        message =
          object: "volume-#{volumeId}"
          priority: 'info'
          loading: 'true'
          content: _(["Volume %s is %s", name, _("deleting")])
        options.$gossipService.receiveMessage message
        obj.itemDelete $scope, volumeId, options, (response, msg) ->
          if response != 200
            reg = /^Invalid volume: Volume still has \d dependent snapshots$/
            if reg.test(msg)
              message =
                object: "volume-#{volumeId}"
                priority: 'error'
                content: _("Snapshots still depent on volume: ") + name
              options.$gossipService.receiveMessage message
            toastr.error _("Failed to delete volume: ") + name
            return false

          angular.forEach $scope.items, (row, index) ->
            if row.id == volumeId
              $scope.items[index].status = 'deleting'
              obj.judgeStatus $scope, $scope.items[index], options
              return false
          obj.getLabileData $scope, volumeId, options

    $scope.dataLoading = false

    $scope.applyVolume = () ->
      if $scope.dataLoading
        return
      $http = options.$http
      serverUrl = $UNICORN.settings.serverURL
      workflowTypesURL = "#{serverUrl}/workflow-request-types"
      $http.get workflowTypesURL
        .success (data) ->
          if !$unicorn.wfTypesMap
            $unicorn.wfTypesMap = {}
          for wfType in data
            $unicorn.wfTypesMap[String(wfType.id)] = wfType.name
            if wfType.name == 'create_volume'
              volumeReq = String(wfType.id)
          if volumeReq
            $scope.dataLoading = true
            options.$dataLoader($scope, volumeReq, 'modal')
        .error (err) ->
          toastr.error _("Error at load apply types.")

    $scope.tryApply = () ->
      options['service'] = 'cinder'
      options['type'] = 'volumes'
      options['callback'] = $scope.applyVolume
      options['projectId'] = $UNICORN.person.project.id
      options['serverUrl'] = $UNICORN.settings.serverURL
      options.$tryApply options

    # handle detaching volume.
    $scope.detachVolume = ->
      obj.action $scope, options, (item, index) ->
        volumeId = item.id
        name = item.display_name || volumeId
        serverId = item.attachments.id
        serName = item.attachments.name
        message =
          object: "instance-#{serverId}"
          priority: 'info'
          loading: 'true'
          content: _(["Instance %s is %s %s ...", serName, _("detaching"), name])
        options.$gossipService.receiveMessage message
        obj.itemDetach $scope, volumeId, serverId, options, (response) ->
          if response != 200
            return false

          angular.forEach $scope.items, (row, index) ->
            if row.id == volumeId
              $scope.items[index].status = 'detaching'
              obj.judgeStatus $scope, $scope.items[index], options
              return false
          obj.getLabileData $scope, volumeId, options

    $scope.$on('update', (event, detail) ->
      for volume in $scope.items
        if volume.id == detail.id
          volume.display_name = detail.display_name
          break
    )

  judgeAction: (action, selectedItems) ->
    #Judge the action button is could click
    restrict = {
      batch: true
      status: null
      resource: null
      attr: null
    }
    canAttachOrDetach = ['data', 'data backup']
    unableStatus = []
    hypervisor_type = $UNICORN.settings.hypervisor_type
    if hypervisor_type \
    and hypervisor_type.toLocaleLowerCase() == 'vmware'
      unableStatus.push 'ACTIVE'
    for key, value of action.restrict
      restrict[key] = value

    if selectedItems.length == 0
      action.enable = false
      return
    else if selectedItems.length == 1
      if !restrict.status
        action.enable = true
        return
      else
        if restrict.status == selectedItems[0].status\
        and selectedItems[0].bootable != 'true'\
        and selectedItems[0].attachments.serverStatus not in unableStatus\
        and selectedItems[0].purpose in canAttachOrDetach
          action.enable = true
        else
          action.enable = false
    else
      if restrict.batch == false
        action.enable = false
        return
      else
        action.enable = true
      if restrict.status
        matchedItems = 0
        for item in selectedItems
          if restrict.status == item.STATUS
            matchedItems += 1
        if matchedItems == selectedItems.length
          action.enable = true
        else
          action.enable = false

  itemChange: (newVal, oldVal, $scope, options) ->
    obj = options.$this
    super newVal, oldVal, $scope, options
    selectedItems = $scope.selectedItems

    for action in $scope.actionButtons.buttons
      if !action.restrict
        continue
      obj.judgeAction(action, selectedItems)
