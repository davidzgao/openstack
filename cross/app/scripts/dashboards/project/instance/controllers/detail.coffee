'use strict'

angular.module('Cross.project.instance')
  .controller 'project.instance.InstanceDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state, $selected,
  $updateDetail, $watchDeleted, $serverDetail, $updateServer) ->
    $scope.currentId = $stateParams.instanceId
    $selected $scope

    if $scope.currentId
      $scope.detail_show = "detail_show"
    else
      $scope.detail_show = "detail_hide"

    # Define the tab at instance detail
    if $stateParams.tab == 'soft-deleted'
      $scope.instance_detail_tabs = [
        {
          name: _('Overview'),
          url: 'project.instance.instanceId.overview',
          available: true
        }
      ]
    else
      $scope.instance_detail_tabs = [
        {
          name: _('Overview'),
          url: 'project.instance.instanceId.overview',
          available: true
        }
        {
          name: _('Log'),
          url: 'project.instance.instanceId.log',
          available: true
        }
        {
          name: _('Console'),
          url: 'project.instance.instanceId.console',
          available: true
        }
        {
          name: _('Monitor'),
          url: 'project.instance.instanceId.monitor',
          available: true
        }
        {
          name: _('Topology'),
          url: 'project.instance.instanceId.topology',
          available: true
        }
      ]

    if $CROSS.settings.use_neutron != true
      $scope.instance_detail_tabs[4].available = false

    if $CROSS.settings.hypervisor_type\
    and $CROSS.settings.hypervisor_type.toLocaleLowerCase() == "vmware"
      $scope.instance_detail_tabs[1].available = false

    $scope.checkActive = () ->
      if $state.current.name == 'admin.instance.instanceId'
        $state.go 'admin.instance'
      for tab in $scope.instance_detail_tabs
        if tab.url == $state.current.name
          tab.active = 'active'
        else
          tab.active = ''

    # Judge tab of log is show/hide
    $scope.getServerLog = () ->
      $cross.serverLog $http, $window, $scope.currentId, 10, (log) ->
        if !log and $stateParams.tab != 'soft-deleted'
          $scope.instance_detail_tabs[1].available = false

    $serverDetail $scope, $updateDetail, $watchDeleted, $state,
    $updateServer

    $scope.checkActive()
    $scope.getServer()

    $scope.$on '$stateChangeSuccess', (event, toState, toParams, fromState, fromParams) ->
      $scope.checkActive()
