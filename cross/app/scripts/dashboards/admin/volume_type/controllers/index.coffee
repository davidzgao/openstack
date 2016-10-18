'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.admin.volume_type')
  .controller 'admin.volume_type.VolumeTypeCtr', ($scope, $http, $window, $q,
                                         $state, $interval, $templateCache,
                                         $compile, $animate) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.note =
      title: _("Volume Type")
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

    notAttach = _("Not attach")
    $scope.columnDefs = [
      {
        field: "display_name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.name}}" ng-bind="item.name"></div>'
      }
      {
        field: "description",
        displayName: _("Description"),
        cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.description}}" ng-bind="item.description"></div>'
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
      pageSize: 1000
      currentPage: 1
    }
    $scope.filterOptions =
      filterText: '',
      useExternalFilter: true

    $scope.volumeTypes = []

    $scope.volumeTypesOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      pageMax: 5
    }

    # Function for get paded instances and assign class for
    # element by status
    setPagingData = (pagedData, total) ->
      $scope.volumeTypes = pagedData
      # Compute the total pages
      $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
      $scope.volumeTypesOpts.data = $scope.volumeTypes
      $scope.volumeTypesOpts.pageCounts = $scope.pageCounts

      if !$scope.$$phase
        $scope.$apply()

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

    volumeTypeGet = ($http, $window, $q, volumeTypeId, callback) ->
      $http.get "#{serverUrl}/volume_types/#{volumeTypeId}"
        .success (volumeType) ->
          callback volumeType
        .error (err) ->
          # TODO(Lixipeng): handle get volumeType error.
          console.log "Failed to get volumeType detail: %s", err

    # Functions about interaction with volumeType
    # --Start--

    listDetailedVolumes = ($http, $window, $q, dataQueryOpts, callback) ->
      $http.get("#{serverUrl}/volume_types", {
        params: dataQueryOpts
      }).success (volumeTypes) ->
        if not volumeTypes
          volumeTypes = []
        callback volumeTypes, volumeTypes.length
      .error (err) ->
        console.log err, "Failed to get projects/servers name"

    # Function for async list instances
    getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        dataQueryOpts = {}
        listDetailedVolumes $http, $window, $q, dataQueryOpts,
        (volumeTypes, total) ->
          setPagingData(volumeTypes, total)
          (callback && typeof(callback) == "function") && callback()
      , 300)

    getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    # Callback for instance list after paging change
    watchCallback = (newVal, oldVal) ->
      tbody = angular.element('tbody.cross-data-table-body')
      tbody.hide()
      loadCallback = () ->
        tbody.show()
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage,
                                 loadCallback

    $scope.$watch('pagingOptions', watchCallback, true)

    # Callback after instance list change
    volumeTypeCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for volumeType in newVal
          if volumeType.isSelected == true
            selectedItems.push volumeType
        $scope.selectedItems = selectedItems

    $scope.$watch('volumeTypes', volumeTypeCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    volumeTypeDelete = ($http, $window, volumeTypeId, callback) ->
      $http.delete("#{serverUrl}/volume_types/#{volumeTypeId}")
        .success (rs) ->
          callback(200)
        .error (err) ->
          callback(err.status)

    # Delete selected servers
    $scope.deleteVolumeType = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        volumeTypeId = item.id
        name = item.name || volumeTypeId
        volumeTypeDelete $http, $window, volumeTypeId, (response) ->
          # TODO(ZhengYue): Add some tips for success or failed
          if response == 200
            # TODO(ZhengYue): Unify the tips for actions
            toastr.success(_('Successfully delete volume type: ') + name)
            getPagedDataAsync($scope.pagingOptions.pageSize,
                              $scope.pagingOptions.currentPage)

    # TODO(ZhengYue): Add loading status
    $scope.refresResource = (resource) ->
      tbody = angular.element('tbody.cross-data-table-body')
      tbody.hide()
      loadCallback = () ->
        tbody.show()
        toastr.options.closeButton = true
      getPagedDataAsync($scope.pagingOptions.pageSize,
                        $scope.pagingOptions.currentPage,
                        loadCallback)

  .controller 'admin.volume_type.VolumeTypeCreateCtr', ($scope, $http, $state, $window) ->
    (new VolumeTypeCreateModal()).initial($scope, {
      $http: $http
      $window: $window
      $state: $state
    })


class VolumeTypeCreateModal extends $cross.Modal
  title: "Create volume type"
  slug: "create_volume_type"

  fields: ->
    [{
      slug: "name"
      label: _ "Name"
      tag: "input"
      restrictions:
        required: true
        len: [1, 35]
    },{
      slug: "description"
      label: _ "Description"
      tag: "textarea"
      restrictions:
        required: false
        len: [0, 512]
    }
    ]

  handle: ($scope, options)->
    $window = options.$window
    serverUrl = $window.$CROSS.settings.serverURL
    $http = options.$http
    $state = options.$state
    name = $scope.form.name
    description = $scope.form.description
    data = {name: name, description: description}
    $http.post "#{serverUrl}/volume_types", data
      .success ->
        toastr.options.closebutton = true
        msg = _("Successfully create volume type: ") + name
        toastr.success msg
        $state.go('admin.volume_type', {}, {reload: true})
      .error ->
        toastr.options.closebutton = true
        msg = _("Failed to create volume type: ") + name
        toastr.error msg
        options.callback false
