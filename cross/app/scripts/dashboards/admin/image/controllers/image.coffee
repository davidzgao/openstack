'use strict'

###*
 # @ngdoc function
 # @name admin.image.ImageCtr
 # @description
 # # ImageCtr
 # Controller of the Cross image and snapshot
###
angular.module('Cross.admin.image')
  .controller 'admin.image.ImagelistCtr', ($scope, $http, $window, $q,
  $state, $interval, $selectedItem, $running, $deleted) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.note =
      title: _("Image")
      buttonGroup:
        download: _("Download")
        create: _("Create")
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
      'saving'
      'queued'
      'downloading'
    ]
    $scope.abnormalStatus = [
      'error'
    ]

    notAttach = _("Not attach")
    $scope.columnDefs = [
      {
        field: "name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.name}}"><a ui-sref="admin.image.imageId.overview({ imageId:item.id })" ng-bind="item.name"></a></div>'
      }
      {
        field: "ownerName",
        displayName: _("owner"),
        cellTemplate: '<div class="ngCellText" data-toggle="tooltip" data-placement="top" title="{{item.project_name}}" ng-bind="item.project_name"></div>'
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

    $scope.searchKey = 'name'
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
      else
        item.labileStatus = 'active'

      item.status = _(item.status)

    # Function for get paded instances and assign class for
    # element by status
    setPagingData = (pagedData, total) ->
      $scope.images = pagedData
      # Compute the total pages
      $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
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
        $scope.singleSelectedItem = $scope.selectedItems[0]
        $scope.singleEnableClass = 'btn-enable'
        $scope.batchActionEnableClass = 'btn-enable'
      else if $scope.selectedItems.length > 1
        $scope.NoSelectedItems = false
        $scope.batchActionEnableClass = 'btn-enable'
        $scope.singleEnableClass = 'btn-disable'
      else
        $scope.NoSelectedItems = true
        $scope.batchActionEnableClass = 'btn-disable'
        $scope.singleEnableClass = 'btn-disable'
        $scope.singleSelectedItem = {}

    imageGet = ($http, $window, $q, imageId, callback) ->
      $http.get "#{serverUrl}/images/#{imageId}"
        .success (image) ->
          if image instanceof Object \
          and image.virtual_size != 'null'
          # The image will be a string value when it had deleted
            image.name = escape(image.name)
            callback image
          else
            callback undefined
        .error (err) ->
          callback undefined
          toastr.error _ "Failed to get image detail: %s", err

    # Functions about interaction with image
    # --Start--

    # periodic get image data which status is 'processing'
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
                projectName = $scope.images[index].project_name
                $scope.images[index] = image
                image.project_name = projectName
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

      freshData = $interval(update, 5000)
      update()

      if (!$.intervalList)
        $.intervalList = []
      $.intervalList.push(freshData)

    listDetailedImages = ($http, $window, $q, dataQueryOpts, callback) ->
      if dataQueryOpts.search == true
        imagesURL = "#{serverUrl}/images/search"
      else
        imagesURL = "#{serverUrl}/images"
      $http.get(imagesURL, {params: dataQueryOpts})
        .success (res) ->
          images = res.data
          for img in images
            img.name = unescape(img.name)
          callback images, res.total
        .error (err) ->
          toastr.error _("Failed to get images")

    # Function for async list instances
    getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        dataQueryOpts =
          all_tenants: true
          limit_from: parseInt(pageSize) * parseInt(currentPage)
          limit_to: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize)
          ec_image_type: 'image'
        if $scope.searched
          dataQueryOpts.search = true
          dataQueryOpts.searchKey = $scope.searchKey
          dataQueryOpts.searchValue = $scope.searchOpts.val
          dataQueryOpts.require_detail = true
        if $scope.currentTab == 'snapshot.tpl.html'
          dataQueryOpts['ec_image_type'] = 'backup'
        listDetailedImages $http, $window, $q, dataQueryOpts,
        (images, total) ->
          setPagingData(images, total)
          (callback && typeof(callback) == "function") &&\
          callback(images)
      , 300)

    getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    # Callback for instance list after paging change
    watchCallback = (newVal, oldVal) ->
      $scope.imagesOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        getPagedDataAsync $scope.pagingOptions.pageSize,
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
        imageId = item.id
        name = item.display_name || imageId
        if item.attachments
          toastr.options.closeButton = true
          msg = item.display_name +
                _(" has attached to instance ") +
                item.attachments
          toastr.warning msg
          return false
        imageDelete $http, $window, imageId, (response) ->
          if response == 200
            angular.forEach $scope.images, (row, index) ->
              if row.id == imageId
                $scope.images[index].status = 'deleting'
                $scope.judgeStatus $scope.images[index]
                return false
            getLabileData(imageId)
            toastr.success(_('Successfully delete image: ') + name)

    $scope.downloadImage = ->
      if not $scope.singleSelectedItem
        return
      id = $scope.singleSelectedItem.id
      name = $scope.singleSelectedItem.name
      # download file with open a new window.
      platform = $CROSS.settings.platform || 'Cross'
      query = "name=#{name}&x-platform=#{platform}"
      window.open("#{serverUrl}/images/#{id}/download?#{query}", "_blank")
      return

    $selectedItem $scope, 'images'

    $scope.refresResource = (resource) ->
      $scope.imagesOpts.data = null
      getPagedDataAsync($scope.pagingOptions.pageSize,
                        $scope.pagingOptions.currentPage)

    $scope.$on('update', (event, detail) ->
      for image in $scope.images
        if image.id == detail.id
          image.name = detail.name
          break
    )
