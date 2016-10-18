'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.project.instance')
  .controller 'project.instance.InstanceCtr', ($scope, $http, $window,
  $q, $state, $interval, $tabs) ->
    serverUrl = $window.$CROSS.settings.serverURL

    $scope.slug = _ 'Instances'

    # Tabs at instance page
    $scope.tabs = [{
      title: _('Instances'),
      template: 'one.tpl.html',
      slug: 'instance',
      enable: true
    }, {
      title: _('Soft-deleted'),
      slug: 'soft-deleted',
      template: 'three.tpl.html'
      enable: false
    }]

    recycle = $window.$CROSS.settings.instanceRecycle
    if recycle == 'true'
      $scope.tabs[1].enable = true

    # Function for tab switch
    $scope.currentTab = 'one.tpl.html'
    $tabs $scope, 'project.instance'

    $scope.buttonGroup = {
      create: _("Create")
      console: _("VNC Console")
      delete: _("Delete")
      more: _("More Action")
      refresh: _("Refresh")
      restore: _("Restore")
    }

    # Category for instance action
    $scope.batchActionEnableClass = 'btn-disable'
    $scope.vncLinkEnableClass = 'btn-disable'

    $scope.batchActions = [
      {
        action: 'reboot',
        verbose: _('Reboot'),
        addition: true,
        addition_message: _('Hard Reboot')
      }
      {action: 'poweron', verbose: _('Power On')}
      {action: 'poweroff', verbose: _('Power Off')}
      {action: 'suspend', verbose: _('Suspend')}
      {action: 'wakeup', verbose: _('Wakeup')}
    ]
    $scope.mantanceActions = [
      {action: 'snapshot', verbose: _('Snapshot')}
      {action: 'resize', verbose: _('Resize')}
    ]

    # Variates for dataTable
    # --start--

    # For sort at table header
    $scope.sort = {
      reverse: false
      sortingOrder: 'created'
    }

    # For tabler footer and pagination or filter
    $scope.showFooter = true
    $scope.unFristPage = false
    $scope.unLastPage = false

    # Category for instance status
    $scope.labileStatus = [
      'BUILD'
      'MIGRATING'
      'HARD_REBOOT'
      'powering-off'
      'VERIFY_RESIZE'
    ]
    $scope.abnormalStatus = [
      'ERROR'
    ]
    $scope.shutdowStatus = [
      'PAUSED'
      'SUSPENDED'
      'STOPPED'
      'SHUTOFF'
    ]

    $scope.columnDefs = [
      {
        field: "name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText enableClick" data-toggle="tooltip" data-placement="top" title="{{item.name}}"><a ui-sref="project.instance.instanceId.overview({ instanceId:item.id })" ng-bind="item[col.field]"></a></div>'
      }
      {
        field: "fixed",
        displayName: _("FixedIP"),
        cellTemplate: '<div class=ngCellText ng-class="open"><li ng-repeat="ip in item.fixed">{{ip}}</li><li ng-if="item.fixed.length==0">{{"" | parseNull}}</li><div class="more-in-cell" title={{showAll}} ng-if="item.fixed.length>1" ng-click="cellOpen($event.currentTarget)"></div></div>'
      }
      {
        field: "floating",
        displayName: _("FloatingIP"),
        cellTemplate: '<div class=ngCellText ng-class="open"><li ng-repeat="ip in item.floating">{{ip}}</li><li ng-if="item.floating.length==0">{{"" | parseNull}}</li><div class="more-in-cell" title={{showAll}} ng-if="item.floating.length>1" ng-click="cellOpen($event.currentTarget)"></div></div>'
      }
      {
        field: "vcpus",
        displayName: "CPU",
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
      {
        field: "ram",
        displayName: _("RAM (GB)"),
        cellTemplate: '<div ng-bind="item[col.field] | unitSwitch"></div>'
      }
      {
        field: "status",
        displayName: _("Status"),
        cellTemplate: '<div class="ngCellText status" ng-class="item.labileStatus"><i></i>{{item.status}}</div>'
      }
    ]
    # --End--
