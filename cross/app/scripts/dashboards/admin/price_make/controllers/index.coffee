'use strict'

angular.module('Cross.admin.price_make')
  .controller 'admin.price_make.PriceMakeCtr', ($scope, $window, $http, $q, $tabs, $state) ->
    serverUrl = $CROSS.settings.serverURL

    $scope.note =
      title: _("Volume Type")
      buttonGroup:
        create: _("Create")
        delete: _("Delete")
        modify: _("Modify")
        refresh: _("Refresh")
      query: _("Query")
      export: _("Export")
      cpuUsage: _("CPU Hours")
      memUsage: _("RAM Hours(GB*Hour)")
      diskUsage: _("Disk Hours(GB*Hour)")
      totalUsage: _("Instances Uptime(Hour)")
      totalPrice: _("Consume Price")
      detailUsage: _("Detail usage of instances")
      usagenull: _("Temporarily no statistic data!")
      all: _("ALL")
      export_all: _("Export All")
      space: ("      ")
    $scope.tabs = [{
      title: _('priceMake')
      template: 'pending.tpl.html'
      enable: true
      slug: 'pending'
    }]
    $scope.currentTab = 'pending.tpl.html'
    $tabs $scope, 'admin.price_make'
    $scope.onClickTab = (tab) ->
      $scope.currentTab = tab.template

    $scope.batchActionEnableClass = 'btn-disable'
    $scope.priceColumnDefs = [
      {
        field: "display_name",
        displayName: _("resourceItem"),
        cellTemplate: '<div class="ngCellText enableClick" title="{{item.name}}" ng-bind="item.showName"></div>'
      }
      {
        field: "value",
        displayName: _("resourcePrice"),
        cellTemplate: '<div class="ngCellText enableClick" title="{{item.value}}" ng-bind="item.value"></div>'
      }
    ]

    $scope.pagingOptions = {
      pageSize: 1000
      currentPage: 1
    }
    $scope.filterOptions =
      filterText: '',
      useExternalFilter: true

    $scope.priceMakeOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: false
      columnDefs: $scope.priceColumnDefs
      pageMax: 5
    }

    getShowName = (item) ->
      showname = ""
      if item.name == "cpu"
        showname =  _ ("Price CPU")
      else if item.name == "ram"
        showname = _ ("Price Ram")
      else if item.name == "volume"
        showname = _ ("Price Volume")
      else if item.name == "network"
        showname = _ ("Price Network")
      return showname

    listDetailedSettings = (callback) ->
      resourcePrice = []
      resourcePriceObj = {}
      $http.get("#{serverUrl}/prices")
        .success (itemList)->
          for i in itemList
            i.showName = getShowName(i)
            resourcePrice.push({name: i.name,value:i.price, showName:i.showName})
            resourcePriceObj[i.name] = i.price
          $scope.resourcePriceObj = resourcePriceObj
          #add by davidzgao
          callback(resourcePrice, resourcePrice.length)
        .error (error)->
          toastr.error _("Failed to get priceService.")

    getPagedDataAsync = (pageSize, currentPage, callback) ->
      dataQueryOpts = {}
      listDetailedSettings (resourcePrice,len_resourcePrice) ->
        $scope.resourcePrice = resourcePrice
        $scope.pageCount = 1
        $scope.priceMakeOpts.data = $scope.resourcePrice
        if !$scope.$$phase
          $scope.$apply()
        if callback
          callback()

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


