'use strict'

###*
 # @ngdoc function
 # @name Unicorn.dashboard.instance:SnapshotCtr
 # @description
 # # SnapshotCtr
 # Controller of the Unicorn
###
angular.module("Unicorn.dashboard.snapshot")
  .controller "dashboard.snapshot.SnapshotCtr", ($scope, $http,
  $q, $window, $state, $interval) ->
    return true
  .controller "dashboard.snapshot.instanceCtr", ($scope, $http,
  $q, $window, $state, $interval) ->

    instanceSnapTable = new InstanceSnapTable($scope)
    instanceSnapTable.init($scope, {
      $state: $state
      $http: $http
      $window: $window
      $interval: $interval
      $q: $q
    })
    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      buttons: [
        {
          type: 'single'
          tag: 'button'
          name: 'del'
          verbose: _("Delete")
          action: $scope.itemDelete
          enable: false
          confirm: _ 'Delete'
          restrict: {
            batch: true
          }
        }
      ]
    }

class InstanceSnapTable extends $unicorn.TableView
  labileStatus: [
    'creating'
    'error_deleting'
    'deleting'
    'saving'
    'queued'
    'downloading'
  ]
  slug: 'instanceSnap'
  columnDefs: [
    {
      field: "name",
      displayName: _("Name"),
      cellTemplate: '<div class="ngCellText" data-toggle="tooltip" data-placement="top" title="{{item.display_name}}" ng-bind="item.display_name"></div>'
    }
    {
      field: "size",
      displayName: _("Size(GB)"),
      cellTemplate: '<div class="ngCellText" data-toggle="tooltip" data-placement="top" title="{{item.size}}" ng-bind="item.size | i18n"></div>'
    }
    {
      field: "volume"
      displayName: _("Instance")
      cellTemplate: '<div class="ngCellText"> {{item.volumeName}}</div>'
    }
    {
      field: "created_at"
      displayName: _("Created At")
      cellTemplate: '<div class="ngCellText">{{item.created_at | dateLocalize | date: "yyyy-MM-dd HH:mm"}}</div>'
    }
    {
      field: "status",
      displayName: _("Status"),
      cellTemplate: '<div class="ngCellText status" ng-class="item.labileStatus"><i data-toggle="tooltip" data-placement="top" title="{{item.status}}"></i>{{item.status | i18n}}</div>'
    }
  ]
  listData: ($scope, options, dataQueryOpts, callback) ->
    serverUrl = $UNICORN.settings.serverURL
    $http = options.$http
    $q = options.$q

    if dataQueryOpts.dataFrom != undefined
      dataQueryOpts.limit_from = dataQueryOpts.dataFrom
      delete dataQueryOpts.dataFrom
    if dataQueryOpts.dataTo != undefined
      dataQueryOpts.limit_to = dataQueryOpts.dataTo
      delete dataQueryOpts.dataTo
    if dataQueryOpts.searchKey
      dataQueryOpts[dataQueryOpts.searchKey] = dataQueryOpts.searchValue
      delete dataQueryOpts.searchKey
      delete dataQueryOpts.searchValue
    dataQueryOpts['snapshot'] = true
    $http.get("#{serverUrl}/volumes")
      .success (res) ->
        if not res
          res =
            data: []
            total: 0
        callback res
        initialImages = res.data
        volumes = []
        for image in initialImages
          if image.purpose == "system backup"
            # NOTE(ZhengYue): Fake name for backup
            image.volumeName = image["os-vol-host-attr:host"]
            volumes.push image
        callback volumes, volumes.length
      .error (err) ->
        toastr.error _("Failed to get images")
    return true

  itemGet: (itemId, options, callback) ->
    $http = options.$http
    serverUrl = $UNICORN.settings.serverURL
    $http.get "#{serverUrl}/cinder/snapshots/#{itemId}"
      .success (image) ->
        callback image
      .error (err, status) ->
        callback undefined


  initialAction: ($scope, options) ->
    super $scope, options

    obj = options.$this
    $http = options.$http
    $window = options.$window
    $state = options.$state

    $scope.$on('update', (event, detail) ->
      for image in $scope.items
        if image.id == detail.id
          image.name = detail.name
          break
    )

    $scope.itemDelete = (type, index) ->
      serverURL = $window.$UNICORN.settings.serverURL
      for item, index in $scope.selectedItems
        imageId = item.id
        name = item.name || imageId
        toastr.success(_(["Deleting instance backup %s ...", name]))
        item.status = 'deleting'
        obj.judgeStatus $scope, item, options
        $http.delete("#{serverURL}/cinder/snapshots/#{imageId}")
          .success (res) ->
            obj.getLabileData $scope, imageId, options
            toastr.success(_(["Successfully deleted backup %s", name]))
          .error (err) ->
            toastr.error(_(["Filed deleted backup %s", name]))

  judgeAction: (action, selectedItems) ->
    restrict = {
      batch: true
    }
    for key, value of action.restrict
      restrict[key] = value
    if selectedItems.length == 0
      action.enable = false
      return
    else
      action.enable = true

  itemChange: (newVal, oldVal, $scope, options) ->
    super newVal, oldVal, $scope, options
    obj = options.$this

    for action in $scope.actionButtons.buttons
      if !action.restrict
        continue
      obj.judgeAction(action, $scope.selectedItems)
