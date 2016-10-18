'use strict'

# TODO(ZhengYue): Optimize this controller:
# Extract common code of each object of monitor item,
# simplify code and make logic clear.

angular.module('Cross.admin.instance')
  .controller 'admin.instance.InstanceMonitorCtr', ($scope) ->
    $scope.monitorTabs = [{
        title: _('Real Time')
        enable: true
        template: 'real-time-monitor'
      },
      {
        title: _('Latest hour')
        enable: true
        template: 'one-hour-ago'
      },
      {
        title: _('Latest day')
        enable: true
        template: 'one-day-ago'
      },
      {
        title: _('Latest week')
        enable: true
        template: 'one-week-ago'
      }
      {
        title: _('Latest month')
        enable: true
        template: 'one-month-ago'
      }
    ]

    $scope.currentMonitorTab = 'real-time-monitor'
    $scope.monitorLineTemplate = 'monitorLine'

    $scope.switchTab = (tab) ->
      $scope.currentMonitorTab = tab.template
      if $.intervalList
        angular.forEach $.intervalList, (task, index) ->
          clearInterval task

    $scope.isActiveTab = (tabUrl) ->
      return tabUrl == $scope.currentMonitorTab
