'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.project.secret_key')
  .controller 'project.secret_key.SecretKeyCtr', ($scope, $http, $window, $q,
                                         $state, $interval, $templateCache,
                                         $compile, $animate) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.note =
      title: _("Secret key")
      buttonGroup:
        create: _("Create")
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
      'attaching'
      'detaching'
      'downloading'
    ]
    $scope.abnormalStatus = [
      'error'
    ]

    $scope.columnDefs = [
      {
        field: "name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText" data-toggle="tooltip" data-placement="top" title="{{item.name}}" ng-bind="item.name"></div>'
      }
      {
        field: "fingerprint"
        displayName: _("Fingerprint")
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]" data-toggle="tooltip" data-placement="top" title="{{item.host}}"></div>'
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

    $scope.pagingOptions =
      showFooter: $scope.showFooter
    $scope.filterOptions =
      filterText: '',
      useExternalFilter: true

    $scope.keys = []

    $scope.keysOpts = {
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
    setPagingData = (pagedData) ->
      $scope.keys = pagedData
      # Compute the total pages
      $scope.keysOpts.data = $scope.keys

    # --End--

    # Functions for handle event from action

    $scope.selectedItems = []
    # TODO(ZhengYue): Add batch action enable/disable judge by status
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

    # Functions about interaction with key
    # --Start--

    listDetailedKeys = ($http, $window, $q, callback) ->
      $http.get("#{serverUrl}/os-keypairs").success (keys) ->
        if not keys
          res =
            data: []
        else
          res =
            data: keys

        callback res.data

    # Function for async list instances
    getPagedDataAsync = (callback) ->
      listDetailedKeys $http, $window, $q, (keys) ->
        setPagingData(keys)
        (callback && typeof(callback) == "function") && callback()

    getPagedDataAsync()

    # Callback after instance list change
    keyCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for key in newVal
          if key.isSelected == true
            selectedItems.push key
        $scope.selectedItems = selectedItems

    $scope.$watch('keys', keyCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    keyDelete = ($http, $window, keyId, callback) ->
      $http.delete("#{serverUrl}/os-keypairs/#{keyId}")
        .success (rs) ->
          callback(200)
        .error (err) ->
          callback(err.status)

    # Reallocate selected servers
    $scope.deleteKey = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        keyId = item.id
        name = item.name || keyId
        keyDelete $http, $window, keyId, (response) ->
          # TODO(ZhengYue): Add some tips for success or failed
          if response == 200
            toastr.success(_('Successfully delete secret key: ') + name)
            $state.go 'project.secret_key', {}, {reload: true}

    # TODO(ZhengYue): Add loading status
    $scope.refresResource = (resource) ->
      tbody = angular.element('tbody.cross-data-table-body')
      tbody.hide()
      loadCallback = () ->
        tbody.show()
      getPagedDataAsync(loadCallback)
