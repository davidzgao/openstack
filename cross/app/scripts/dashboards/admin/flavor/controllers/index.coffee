'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.admin.flavor')
  .controller 'admin.flavor.FlavorCtr', ($scope, $http, $q, $window) ->
    serverUrl = $window.$CROSS.settings.serverURL
    $scope.note =
      title: _("Flavor")
      buttonGroup:
        refresh: _("Refresh")

    # For sort at table header
    $scope.sort = {
      reverse: false
    }
    # For tabler footer and pagination or filter
    $scope.showFooter = true
    $scope.columnDefs = [
      {
        field: "name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText" ng-click="detailShow(item.id)" data-toggle="tooltip" data-placement="top" title="{{item.name}}"ng-bind="item[col.field]"></div>'
      }
      {
        field: "vcpus",
        displayName: _("CPU"),
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]" data-toggle="tooltip" data-placement="top" title="{{item.vcpus}}"></div>'
      }
      {
        field: "ram",
        displayName: _("Memory(GB)"),
        cellTemplate: '<div ng-bind="item[col.field]" class="ngCellText" data-toggle="tooltip" data-placement="top" title="{{item.ram}}"></div>'
      }
      {
        field: "disk",
        displayName: _("Disk(GB)"),
        cellTemplate: '<div ng-bind="item[col.field]" class="ngCellText" data-toggle="tooltip" data-placement="top" title="{{item.disk}}"></div>'
      }
    ]

    $scope.searchOpts = {
      search: () ->
        $scope.search($scope.searchKey, $scope.searchOpts.val)
      showSearch: true
    }

    # For tabler footer and pagination or filter
    $scope.pagingOptions = {
      pageSize: 15
      currentPage: 1
    }
    $scope.filterOptions =
      filterText: '',
      useExternalFilter: true

    $scope.flavors = [
    ]

    $scope.flavorOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: false
      columnDefs: $scope.columnDefs
      pageMax: 5
    }
    $scope.selectedItems = []

    # Function for get paded instances and assign class for
    # element by status
    setPagingData = (pagedData, total) ->
      $scope.flavors = pagedData
      # Compute the total pages
      $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
      $scope.flavorOpts.data = $scope.flavors
      $scope.flavorOpts.pageCounts = $scope.pageCounts

      if !$scope.$$phase
        $scope.$apply()
    # --End--

    # get flavors detail.
    listDetailedFlavors = ($http, $window, $q, dataQueryOpts, callback) ->
      if dataQueryOpts.search == true
         flavorsURL = "#{serverUrl}/os-flavors/search"
      else
         flavorsURL = "#{serverUrl}/os-flavors"
      $http.get(flavorsURL, {
        params: dataQueryOpts
      }).success (res) ->
        if not res
          res =
            data: []
            total: 0
        flavors = []
        for flavor in res.data
          ram = flavor.ram / 1024.0
          ram = Math.round(ram * 100) / 100
          flavor.ram = ram
          flavor.disk = Number(flavor.disk)
          flavor.vcpus = Number(flavor.vcpus)
          flavors.push(flavor)
        callback flavors, res.total

    # Function for async list instances
    getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        dataQueryOpts =
          limit_from: parseInt(pageSize) * parseInt(currentPage)
          limit_to: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize) - 1
        if $scope.searched
          dataQueryOpts.search = true
          dataQueryOpts.searchKey = $scope.searchKey
          dataQueryOpts.searchValue = $scope.searchOpts.val
          dataQueryOpts.require_detail = true
        listDetailedFlavors $http, $window, $q, dataQueryOpts,
        (flavors, total) ->
          setPagingData(flavors, total)
          (callback && typeof(callback) == "function") && \
          callback(flavors)
      , 300)

    getPagedDataAsync($scope.pagingOptions.pageSize,
                      $scope.pagingOptions.currentPage)

    watchCallback = (newVal, oldVal) ->
      $scope.flavorOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        getPagedDataAsync $scope.pagingOptions.pageSize,
                          $scope.pagingOptions.currentPage

    $scope.$watch('pagingOptions', watchCallback, true)

    $scope.refresResource = (resource) ->
      $scope.flavorOpts.data = null
      getPagedDataAsync($scope.pagingOptions.pageSize,
                        $scope.pagingOptions.currentPage)
