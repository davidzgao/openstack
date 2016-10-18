'use strict'

angular.module('Cross.admin.apply_setting')
  .controller 'admin.apply_setting.ApplySettingCtr', ($scope, $http,
  $window, $q, $state, $interval) ->
    $scope.slug = _ 'Apply'
    $scope.tabs = [{
      title: _('Apply Type')
      template: 'types.tpl.html'
      enable: true
    }]

    $scope.currentTab = 'types.tpl.html'

    $scope.onClickTab = (tab) ->
      $scope.currentTab = tab.template
    $scope.isActiveTab = (tabUrl) ->
      return tabUrl == $scope.currentTab

    $scope.columnDefs = [
      {
        field: "display_name"
        displayName: _("Apply Type Name")
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]"></div>'
      }
      {
        field: "status"
        displayName: _("Auto Approve Status")
        cellTemplate: '<div class="ngCellText status" ng-class="item.status"><i data-toggle="tooltip" data-placement="top" title="{{itme.STATUS}}"></i>{{item.STATUS}}</div>'
      }
      {
        field: "status"
        displayName: _("Setting Auto/Manual")
        cellTemplate: '<div class="switch-button" switch-button status="item.condition" verbose="item.CONDITION" action="addition(item.id, item.condition)" enable="item.canDisable"></div>'
      }
    ]

    $scope.selectedItems = []

    $scope.pagingOptions = {
      pageSizes: [15]
      pageSize: 15
      currentPage: 1
      showFooter: false
      showCheckbox: false
    }

    $scope.types = []

    $scope.switchAuto = (typeId, status) ->
      content = {
        id: typeId
      }
      if status == 'on'
        content.auto_approve = '0'
      else
        content.auto_approve = '1'

      serverURL = $window.$CROSS.settings.serverURL
      fixArgs = "/workflow-request-types/#{typeId}"
      workflowTypeURL = "#{serverURL}#{fixArgs}"
      $http.put workflowTypeURL, content
        .success (data, status, headers) ->
          toastr.success(_("Success setting apply type!"))
          item = data['workflow-request-type']
          angular.forEach $scope.types, (type, index) ->
            if type.id == item.id
              if item.auto_approve == '1'
                type.auto_approve = 1
              if item.auto_approve == '0'
                type.auto_approve = 0
        .error (data, status, headers) ->
          toastr.error(_("Falied to set auto approve!"))
          $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                                   $scope.pagingOptions.currentPage)

    $scope.typesOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: false
      columnDefs: $scope.columnDefs
      pageMax: 5
      addition: $scope.switchAuto
      sort:
        reverse: false
    }

    $scope.setPagingData = (metaData, total) ->
      pagedData = []
      for item in metaData
        pagedData.push item if item.enable == 1
      $scope.types = pagedData
      $scope.totalServerItems = total
      $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
      $scope.typesOpts.data = $scope.types
      $scope.typesOpts.pageCounts = $scope.pageCounts

      if !$scope.$$phase
        $scope.$apply()

    $scope.getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        serverURL = $window.$CROSS.settings.serverURL
        fixArgs = '/workflow-request-types'
        workflowTypeURL = "#{serverURL}#{fixArgs}"
        $http.get(workflowTypeURL)
          .success (data, status, headers) ->
            $scope.setPagingData(data, data.length)
          .error (data, status, headers) ->
            $scope.setPagingData([], 0)
            toastr.error(_("Failed to get apply types!"))
        (callback && typeof(callback) == "function") && callback()
      , 300)

    $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    watchCallback = (newVal, oldVal) ->
      $scope.typesOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage

    $scope.$watch('pagingOptions', watchCallback, true)

    typeCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for type in newVal
          if type.name == 'quota_request'
            type.canDisable = false
          else
            type.canDisable = true
          if type.auto_approve == 1
            type.status = 'active'
            type.STATUS = _ ("Turned On")
            type.condition = 'on'
            type.CONDITION = _ 'on'
          if type.auto_approve == 0
            type.status = 'stoped'
            type.STATUS = _ ("Turned Off")
            type.condition = 'off'
            type.CONDITION = _ 'off'
          if type.isSelected == true
            selectedItems.push type

      $scope.selectedItems = selectedItems

    $scope.$watch('types', typeCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)
