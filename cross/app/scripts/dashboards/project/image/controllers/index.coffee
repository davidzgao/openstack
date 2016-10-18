'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.project.image')
  .controller 'project.image.ImageCtr', ($scope, $http, $window, $q,
  $state, $stateParams, $interval, $selectedItem, $deleted, $running) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.tab = $stateParams['tab']
    $scope.note =
      title: _("Image")
      buttonGroup:
        create: _("Create")
        delete: _("Delete")
        refresh: _("Refresh")

    # Tabs at instance page
    $scope.tabs = [{
      title: _('Project image')
      slug: 'privateImg'
    }, {
      title: _('Public image')
      slug: 'publicImg'
    }]
    if not $scope.tab
      $scope.tab = 'privateImg'
    $scope.selectedTab = $scope.tab
    $scope.changeTab = (name) ->
      params =
        reload: true
        inherit: false
      hash =
        tab: name
      if name == 'privateImg'
        hash = null
      $state.go "project.image", hash, params

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
      'saving'
      'queued'
      'downloading'
    ]
    $scope.abnormalStatus = [
      'error'
    ]

    $scope.columnDefs = [
      {
        field: "name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.name}}"><a ui-sref="project.image.imageId.overview({ imageId:item.id })" ng-bind="item.name"></a></div>'
      }
      {
        field: "ownerName",
        displayName: _("owner"),
        cellTemplate: '<div class="ngCellText" data-toggle="tooltip" data-placement="top" title="{{item.ownerName}}" ng-bind="item.ownerName"></div>'
      }
      {
        field: "type",
        displayName: _("Type"),
        cellTemplate: '<div class="ngCellText" data-toggle="tooltip" data-placement="top" title="{{item.type}}" ng-bind="item.type"></div>'
      }
      {
        field: "disk_format"
        displayName: _("Format")
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]" data-toggle="tooltip" data-placement="top" title="{{item.disk_format}}"></div>'
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

    $scope.images = []

    $scope.imagesOpts = {
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
      else if item.status == 'deleted'
        item.labileStatus = 'delelted'
      else
        item.labileStatus = 'active'

      item.status = _(item.status)

    # Function for get paded instances and assign class for
    # element by status
    setPagingData = (pagedData, total) ->
      # Compute the total pages
      $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
      $scope.images = []
      for item in pagedData
        if $scope.tab == "publicImg" and item.is_public == "true"
          $scope.images.push item
        else
          $scope.images.push item if item.container_format != 'null'

      $scope.imagesOpts.data = $scope.images
      $scope.imagesOpts.pageCounts = $scope.pageCounts

      for item in pagedData
        item.pureStatus = item.status
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

    imageGet = ($http, $window, $q, imageId, callback) ->
      $http.get "#{serverUrl}/images/#{imageId}"
        .success (image) ->
          image.name = escape(image.name)
          callback image
        .error (err) ->
          # TODO(Lixipeng): handle get image error.
          console.log "Failed to get image detail: %s", err
          callback()

    # Functions about interaction with image
    # --Start--

    # periodic get volume data which status is 'processing'
    $scope.labileImageQueue = {}
    getLabileData = (imageId) ->
      if $scope.labileImageQueue[imageId]
        return
      else
        $running $scope, imageId
        $scope.labileImageQueue[imageId] = true
      update = () ->
        $http.get("#{serverUrl}/images/#{imageId}").success (image) ->
          if image
            if image.status not in $scope.labileStatus
              $interval.cancel(freshData)
              $running $scope, imageId
              delete $scope.labileImageQueue[image.id]

            angular.forEach $scope.images, (row, index) ->
              if row.id == image.id
                image.pureStatus = image.status
                $scope.judgeStatus image
                image.isSelected = $scope.images[index].isSelected
                image.ownerName = row.ownerName
                image.type = row.type
                $scope.images[index] = image
                if image.pureStatus == 'deleted'
                  $scope.images.splice(index, 1)
                  $deleted $scope, imageId
          else
            $interval.cancel(freshData)
            $deleted $scope, imageId
            delete $scope.labileImageQueue[imageId]
            angular.forEach $scope.images, (row, index) ->
              if row.id == imageId
                $scope.images.splice(index, 1)

      if (!$.intervalList)
        $.intervalList = []
      $.intervalList.push(freshData)

      freshData = $interval(update, 5000)
      update()

    listDetailedImages = ($http, $window, $q, dataQueryOpts, callback) ->
      $http.get("#{serverUrl}/images", {params: dataQueryOpts})
        .success (res) ->
          if not res
            res =
              data: []
              total: 0
          callback res.data, res.total
          owners = []
          for image in $scope.images
            image.name = unescape(image.name)
            owners.push image.owner
            if image.properties
              properties = JSON.parse image.properties
              type = properties['image_type']
              if type == 'backup' or type == 'snapshot'
                image.type = _("Instance backup")
              else
                image.type = _("Image")
          if not owners.length
            return
          params =
            params:
              fields: '["name"]'
              ids: JSON.stringify owners
          $http.get "#{serverUrl}/projects/query", params
            .success (ownerDict) ->
              for image in $scope.images
                if ownerDict[image.owner]
                  image.ownerName = ownerDict[image.owner].name
            .error (err) ->
              console.error "Failed to get tenant names:", err
        .error (err) ->
          console.error "Failed to get images:", err
          toastr.error _("Failed to get images")


    # Function for async list instances
    getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        dataQueryOpts =
          limit_from: parseInt(pageSize) * parseInt(currentPage)
          limit_to: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize)
        if $scope.tab == 'publicImg'
          dataQueryOpts['all_tenants'] = true
          dataQueryOpts['is_public'] = 'true'
        listDetailedImages $http, $window, $q, dataQueryOpts,
        (images, total) ->
          setPagingData(images, total)
          (callback && typeof(callback) == "function") && callback()
      , 300)

    getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    # Callback for instance list after paging change
    watchCallback = (newVal, oldVal) ->
      $scope.imagesOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage

    $scope.$watch('pagingOptions', watchCallback, true)

    # Callback after instance list change
    imageCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for image in newVal
          if $scope.selectedItemId
            if image.id == $scope.selectedItemId
              image.isSelected = true
              $scope.selectedItemId = undefined
          if image.pureStatus in $scope.labileStatus
            getLabileData(image.id)
          if image.isSelected == true
            selectedItems.push image
        $scope.selectedItems = selectedItems

    $scope.$watch('images', imageCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    imageDelete = ($http, $window, imageId, callback) ->
      $http.delete("#{serverUrl}/images/#{imageId}")
        .success (rs) ->
          callback(200)
        .error (err) ->
          callback(err.status)

    # Delete selected servers
    $scope.deleteImage = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        if item.owner != $CROSS.person.project.id
          toastr.error _("Can not delete image of other projects")
          return
        imageId = item.id
        name = item.name || imageId
        if item.attachments
          toastr.options.closeButton = true
          msg = item.display_name +
                _(" has attached to instance ") +
                item.attachments
          toastr.warning msg
          return false
        imageDelete $http, $window, imageId, (response) ->
          # TODO(ZhengYue): Add some tips for success or failed
          if response == 200
            # TODO(ZhengYue): Unify the tips for actions
            angular.forEach $scope.images, (row, index) ->
              if row.id == imageId
                $scope.images[index].status = 'deleting'
                $scope.judgeStatus $scope.images[index]
                return false
            getLabileData(imageId)
            toastr.success(_('Successfully delete image: ') + name)

    $selectedItem $scope, 'images'

    $scope.refresResource = (resource) ->
      $scope.imagesOpts.data = null
      getPagedDataAsync($scope.pagingOptions.pageSize,
                        $scope.pagingOptions.currentPage)
