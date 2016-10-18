'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.project.security_group')
  .controller 'project.security_group.SecurityGroupCtr', ($scope,
  $http, $window, $q, $state, $interval, $selectedItem) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.note =
      title: _("Security group")
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

    $scope.abnormalStatus = [
      'error'
    ]

    notAttach = _("Not attach")
    $scope.columnDefs = [
      {
        field: "name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText enableClick" ng-click="detailShow(item.id)" data-toggle="tooltip" data-placement="top" title="{{item.name}}"><a ui-sref="project.security_group.securityGroupId({ securityGroupId:item.id })" ng-bind="item.name"></a></div>'
      }
      {
        field: "description"
        displayName: _("Description")
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

    $scope.securityGroups = []

    $scope.securityGroupsOpts = {
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
      $scope.securityGroups = pagedData
      # Compute the total pages
      $scope.securityGroupsOpts.data = $scope.securityGroups

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

    # Functions about interaction with securityGroup
    # --Start--

    listDetailedSecurityGroups = ($http, $window, $q, callback) ->
      queryOpts = {}
      if $CROSS.settings.use_neutron
        queryOpts =
          tenant_id: $CROSS.person.project.id
      $cross.networks.listSecurityGroups $http, queryOpts, (err, securityGroups) ->
        if err
          securityGroups = []
          toastr.error _("Failed to get security groups")

        callback securityGroups

    # Function for async list instances
    getPagedDataAsync = (callback) ->
      listDetailedSecurityGroups $http, $window, $q, (securityGroups) ->
        setPagingData(securityGroups)
        (callback && typeof(callback) == "function") && callback()

    getPagedDataAsync()

    # Callback after instance list change
    securityGroupCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for securityGroup in newVal
          if $scope.selectedItemId
            if ('' + securityGroup.id + '') == $scope.selectedItemId
              securityGroup.isSelected = true
              $scope.selectedItemId = undefined
          if securityGroup.isSelected == true
            selectedItems.push securityGroup
        $scope.selectedItems = selectedItems

    $scope.$watch('securityGroups', securityGroupCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    securityGroupDelete = ($http, $window, securityGroupId, callback) ->
      $cross.networks.securityGroupDelete $http, securityGroupId, (err, rs) ->
        if not err
          callback(200)
        else
          callback(err.status)

    # delete selected servers
    $scope.deleteSecurityGroup = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        securityGroupId = item.id
        name = item.name || securityGroupId
        securityGroupDelete $http, $window, securityGroupId, (response) ->
          # TODO(ZhengYue): Add some tips for success or failed
          if response == 200
            toastr.success(_('Successfully delete security group: ') + name)
            $state.go 'project.security_group', {}, {reload: true}

    $selectedItem $scope, 'securityGroups'

    $scope.refresResource = (resource) ->
      $scope.securityGroupsOpts.data = null
      getPagedDataAsync()
