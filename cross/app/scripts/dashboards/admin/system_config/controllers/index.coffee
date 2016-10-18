
angular.module('Cross.admin.system_config')
  .controller 'admin.system_config.OptionCtr', ($scope, $http, $state,
  $tabs, $window, $q) ->
    $scope.slug = _ 'System Config'
    $scope.tabs = [
      {
        title: _ 'Options'
        template: 'option.html'
        enable: true
      }
    ]

    $scope.currentTab = 'option.html'
    $tabs $scope, 'admin.system_config'

    $scope.showFooter = true
    $scope.columnDefs = [
      {
        field: "name"
        displayName: _("Name")
        cellTemplate: '<div class="ngCellText" ng-bind="item.display_name"></div>'
      }
      {
        field: "value"
        displayName: _("Value")
        cellTemplate: '<div class="ngCellText" ng-bind="item.value"></div>'
      }
      {
        field: "description"
        displayName: _("Description")
        cellTemplate: '<div class="ngCellText" ng-bind="item.description"></div>'
      }
    ]

    $scope.pagingOptions = {
      pageSize: 15
      currentPage: 1
    }

    $scope.optionOpts = {
      showCheckbox: true
      pagingOptions: $scope.pagingOptions
      columnDefs: $scope.columnDefs
    }

    $scope.options = []

    $scope.setPagingData = (pagedData, total) ->
      $scope.options = pagedData
      $scope.totalServerItems = total
      $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
      # FIXME (liuhaobo): password is still displayed in the
      # packet, should do some optimizations in the future.
      angular.forEach $scope.options, (item) ->
        if item.key == 'email_sender_password'
          item.value = '******'
      $scope.optionOpts.data = $scope.options
      $scope.optionOpts.pageCounts = $scope.pageCounts

      if !$scope.$$phase
        $scope.$apply()

    $scope.getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        serverURL = $window.$CROSS.settings.serverURL
        fixArgs = '/options'
        pageArg = "?current_page=#{currentPage}&page_size=#{pageSize}"

        optionURL = "#{serverURL}#{fixArgs}#{pageArg}"
        optionsQ = $http.get optionURL
        optionGroupsQ = $http.get "#{serverURL}/option_groups"
        $q.all([optionGroupsQ, optionsQ])
          .then (values) ->
            optionGroups = values[0].data
            options = values[1].data
            groupMap = {}
            for group in optionGroups.list
              groupMap[group.id] = group.display_name

            for option in options.list
              option.group_name = groupMap[option.group_id] || _ 'Default'
              if not option.description
                option.description = _ "None"
            $scope.setPagingData(options.list, options.total)
        (callback && typeof(callback) == "function") && callback()
      , 300)

    $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    watchCallback = (newVal, oldVal) ->
      $scope.optionOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage

    $scope.$watch('pagingOptions', watchCallback, true)

    $scope.selectChange = () ->
      if $scope.selectedItems.length == 1
        $scope.editEnabledClass = 'btn-enable'
      else
        $scope.editEnabledClass = 'btn-disable'

    optionCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for option in newVal
          if $scope.selectedApplyId
            if option.id == $scope.selectedApplyId
              option.isSelected = true
              $scope.selectedApplyId = undefined
          if option.isSelected == true
            selectedItems.push option

        $scope.selectedItems = selectedItems

    $scope.$watch('options', optionCallback, true)
    $scope.$watch('selectedItems', $scope.selectChange, true)

    $scope.optionCreate = () ->
      $state.go 'admin.system_config.create'

    $scope.editOption = () ->
      if $scope.editEnabledClass == 'btn-disable'
        return
      else
        optionId = $scope.selectedItems[0].id
        $state.go 'admin.system_config.optionId.edit', {optionId: optionId}

    $scope.note = {
      buttonGroup: {
        edit: _("Edit")
      }
    }

    $scope.editEnabledClass = 'btn-disable'
    $scope.selectedItems = []
