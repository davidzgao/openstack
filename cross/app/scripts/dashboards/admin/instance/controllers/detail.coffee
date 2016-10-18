'use strict'

angular.module('Cross.admin.instance')
  .controller 'admin.instance.InstanceDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state, $animate, $selected, $detailShow) ->

    $scope.currentId = $stateParams.instanceId
    $selected $scope

    $scope.$emit("selected", $scope.currentId)

    $detailShow $scope

    # Define the tab at instance detail
    if $stateParams.tab == 'soft-deleted'
      $scope.detail_tabs = [
        {
          name: _('Overview'),
          url: 'admin.instance.instanceId.overview',
          available: true
        }
      ]
    else
      $scope.detail_tabs = [
        {
          name: _('Overview'),
          url: 'admin.instance.instanceId.overview',
          available: true
        }
        {
          name: _('Log'),
          url: 'admin.instance.instanceId.log',
          available: true
        }
        {
          name: _('Console'),
          url: 'admin.instance.instanceId.console',
          available: true
        }
        {
          name: _('Monitor'),
          url: 'admin.instance.instanceId.monitor',
          available: true
        }
        {
          name: _('Topology'),
          url: 'admin.instance.instanceId.topology',
          available: true
        }
      ]

    if $CROSS.settings.use_neutron != true
      $scope.detail_tabs[4].available = false

    if $CROSS.settings.hypervisor_type\
    and $CROSS.settings.hypervisor_type.toLocaleLowerCase() == "vmware"
      $scope.detail_tabs[1].available = false
      $scope.detail_tabs[3].available = false

    $scope.checkActive = () ->
      if $state.current.name == 'admin.instance.instanceId'
        $state.go 'admin.instance'
      for tab in $scope.detail_tabs
        if tab.url == $state.current.name
          tab.active = 'active'
        else
          tab.active = ''

    # Judge tab of log is show/hide
    $scope.getServerLog = () ->
      $cross.serverLog $http, $window, $scope.currentId, 10, (log) ->
        if !log and $stateParams.tab != 'soft-deleted'
          $scope.detail_tabs[1].available = false

    $scope.getServerLog()
    $scope.checkActive()

    $scope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams) ->
      $scope.checkActive()
