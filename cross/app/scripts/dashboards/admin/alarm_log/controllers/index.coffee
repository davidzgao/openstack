'use strict'

angular.module('Cross.admin.alarm_log')
  .controller 'admin.alarm_log.AlarmLogCtr', ($scope, $http, $window,
  $q, $state, $tabs) ->
    $scope.slug = _ 'Alarm Log'
    $scope.tabs = [
      {
        title: _('Unread')
        template: 'unread.tpl.html'
        enable: true
      }
      {
        title: _('Read')
        template: 'read.tpl.html'
        enable: true
      }
    ]

    $scope.currentTab = 'unread.tpl.html'
    $tabs $scope, 'admin.alarm_log'

    $scope.sort = {
      sortingOrder: 'create_at'
      reverse: true
    }

    $scope.showFooter = true
    $scope.unFristPage = false
    $scope.unLastPage = false

    $scope.refesh = _("Refresh")
    $scope.read = _("Mark as Read")

    # TODO(ZhengYue): Fix the display after click instance id
    $scope.jump = (type, resource_id, noClick) ->
      if type == 'instance'
        # The noClick's value is enableClick is for styles
        if noClick != 'enableClick'
          return
        else
          $state.go "admin.instance.instanceId.overview",
          {instanceId: resource_id}
      else if type == 'hardware'
        $cross.listHosts($http, $window, $q, (hosts) ->
          for host in hosts
            if resource_id == host.hypervisor_hostname
              $state.go "admin.compute_node.hostId/:hostName.overview",
              {hostId: host.id, hostName: resource_id}
              break
        )
      else if type == 'alarm_id'
        $state.go "admin.alarm_rule.ruleId.overview", {ruleId: resource_id}

    $scope.columnDefs = [
      {
        field: "resource_type"
        displayName: _("Object Type")
        cellTemplate: '<div class="ngCellText resource-type" ng-bind="item.resource_type"></div>'
      }
      {
        field: "resource_name"
        displayName: _("Relative Resource")
        cellTemplate: '<div class="ngCellText {{item.noClick}}"><span ng-click="addition.jump(item.reason_data.resource_type, item.resource_id, item.noClick)" ng-bind="item.resource_name"></span></div>'
      }
      {
        field: "alarm_id"
        displayName: _("Alarm Rule")
        cellTemplate: '<div class="ngCellText enableClick" ng-bind="item.alarm_meta" ng-click="addition.jump(col.field, item.alarm_id)"></div>'
      }
      {
        field: "triggered_at"
        displayName: _("Triggered At")
        cellTemplate: '<div class="ngCellText">{{item.triggered_at | dateLocalize | date:"yyyy-MM-dd HH:mm"}}</div>'
      }
    ]
