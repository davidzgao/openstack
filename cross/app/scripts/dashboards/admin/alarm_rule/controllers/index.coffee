'use strict'

angular.module('Cross.admin.alarm_rule')
  .controller 'admin.alarm_rule.AlarmRuleCtr', ($scope, $http, $window,
  $q, $interval, $state, $tabs) ->
    $scope.slug = _ 'Alarm Rule'
    $scope.tabs = [
      {
        title: _('Alarm Rule')
        template: 'alarm.tpl.html'
        enable: true
      }
    ]

    $scope.currentTab = 'alarm.tpl.html'
    $tabs $scope, 'admin.alarm_rule'

    $scope.sort = {
      reverse: false
    }

    $scope.createAction = _("Create")
    $scope.deleteAction = _("Delete")
    $scope.refesh = _("Refresh")
    $scope.more = _("More Action")

    $scope.showFooter = true
    $scope.unFristPage = false
    $scope.unLastPage = false
    $scope.columnDefs = [
      {
        field: "name"
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText" data-toggle="tooltip" data-placement="top" title="{{item.name}}"><a ui-sref="admin.alarm_rule.ruleId.overview({ruleId:item.alarm_id})" ng-bind="item[col.field]"></a></div>'
      }
      {
        field: "severity"
        displayName: _("Severity")
        cellTemplate: '<div class="ngCellText" ng-bind="item.severity_level">'
      }
      {
        field: "meter"
        displayName: _("Meter Item")
        cellTemplate: '<div class="ngCellText" ng-bind="item.thresholdRule.meter_name">'
      }
      {
        field: "statistic"
        displayName: _("Statistic Type")
        cellTemplate: '<div class="ngCellText" ng-bind="item.thresholdRule.statistic">'
      }
      {
        field: "operator"
        displayName: _("Comparison Operator")
        cellTemplate: '<div class="ngCellText" ng-bind="item.thresholdRule.comparison_operator">'
      }
      {
        field: "threshold"
        displayName: _("Threshold")
        cellTemplate: '<div class="ngCellText" ng-bind="item.thresholdRule.threshold">'
      }
      {
        field: "enabled",
        displayName: _("Status"),
        cellTemplate: '<div class="switch-button" switch-button status="item.condition" verbose="item.ENABLED" action="addition(item.alarm_id, item.enabled)" enable="true">{{item.ENABLED}}</div>'
      }
    ]

    $scope.singleSelectedItem = []
    $scope.selectedItems = []

    $scope.couldEdit = 'btn-disable'
    $scope.edit = _("Edit")
    $scope.editActionTemplate = '<a ur-sref="admin.alarm_rule.ruleId.edit({ruleId: singleSelectedItem.alarm_id})" class="btn" ng-class="couldEdit" id="alarm_rule_edit"><i class="edit"></i>{{edit}}</a>'

    $scope.deleteEnableClass = 'btn-disable'
    $scope.selectChange = () ->
      if $scope.selectedItems.length == 1
        $scope.singleSelectedItem = $scope.selectedItems[0]
        $scope.deleteEnableClass = 'btn-enable'
        $scope.couldEdit = 'btn-enable'
      else if $scope.selectedItems.length > 1
        $scope.deleteEnableClass = 'btn-enable'
        $scope.couldEdit = 'btn-disable'
        $scope.singleSelectedItem = {}
      else
        $scope.singleSelectedItem = {}
        $scope.couldEdit = 'btn-disable'
        $scope.deleteEnableClass = 'btn-disable'

    $scope.pagingOptions = {
      pageSizes: [15, 25, 50]
      pageSize: 15
      currentPage: 1
    }

    $scope.rules = []
    $scope.addition = (ruleId, enable) ->
      if enable
        rule_enable = false
      else
        rule_enable = true
      for rule in $scope.rules
        if rule.alarm_id == ruleId
          currentRule = rule
          break
      param = {
        alarm_id: ruleId
        enabled: rule_enable
        severity: currentRule.severity
        name: currentRule.name
        threshold_rule: currentRule.threshold_rule
        type: 'threshold'
      }
      ruleURL = $CROSS.settings.serverURL + '/alarm_rule/' + ruleId
      $http.put ruleURL, param
        .success (data) ->
          if data
            for rule, index in $scope.rules
              if rule.alarm_id == data.alarm_id
                if data.enabled
                  rule.condition = 'on'
                  rule.enabled = true
                else
                  rule.condition = 'off'
                  rule.enabled = false
                break
          toastr.success _("Success to update alarm rule status.")
        .error (err) ->
          for rule, index in $scope.rules
            if rule.alarm_id == ruleId
              if param.enabled
                rule.condition = 'off'
              else
                rule.condition = 'on'
              break
          toastr.error _("Failed to update alarm rule status.")
      return
    $scope.rulesOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      showFooter: false
      addition: $scope.addition
    }

    $scope.setPagingData = (pagedData, total) ->
      $scope.rules = pagedData
      $scope.totalServerItems = total | pagedData.length
      $scope.pageCounts = 1
      $scope.rulesOpts.data = $scope.rules
      $scope.rulesOpts.pageCounts = $scope.pageCounts

      if !$scope.$$phase
        $scope.$apply()

    $scope.getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        $cross.listAlarmRule $http, $window, (data) ->
          $scope.setPagingData(data)
          (callback && typeof(callback) == "function") && callback()
      , 300)

    $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    $window.$CROSS.alarmMeterItem = {
      cpu_util: _ 'CPU Util'
      'disk.read.bytes.rate': _ "Disk Read Rate"
      'disk.write.bytes.rate': _ "Disk Write Rate"
      'networking.incoming.rate': _ "Network Incoming Rate"
      'networking.outgoing.rate': _ "Network Outgoing Rate"
      'memory.usage': _ "Memory Util"
    }
    $window.$CROSS.alarmOperator = {
      eq: _ 'Equal'
      gt: _ 'Greater-than'
      lt: _ 'Less-than'
      le: _ 'Less-than or Equal'
      ge: _ 'Greater-than or Equal'
    }
    $window.$CROSS.alarmStatType = {
      avg: _ 'Average'
      max: _ "Max"
      min: _ 'Min'
    }
    $window.$CROSS.alarmSeverity = {
      low: _ 'Low'
      moderate: _ 'Moderate'
      critical: _ 'Critical'
    }

    # Parse the args of alarm rule
    trans = (items) ->
      meterMap = $window.$CROSS.alarmMeterItem
      statisticMap = $window.$CROSS.alarmStatType
      operatorMap = $window.$CROSS.alarmOperator
      severityMap = $window.$CROSS.alarmSeverity
      selectedItems = []
      for item in items
        thresholdRule = item.threshold_rule
        meter_name = meterMap[thresholdRule.meter_name]
        statistic = statisticMap[thresholdRule.statistic]
        operator = operatorMap[thresholdRule.comparison_operator]
        severity = severityMap[item.severity]
        item.severity_level = severity
        if $scope.selectedRuleId
          if item.alarm_id == $scope.selectedRuleId
            item.isSelected = true
            $scope.selectedRuleId = undefined
          else
            item.isSelected = false
        if thresholdRule.meter_name.indexOf('rate') > 0
          threshold = thresholdRule.threshold / 1024
          threshold = threshold + ' MB/s'
        else
          threshold = thresholdRule.threshold + ' %'
        item.thresholdRule = {
          meter_name: meter_name
          statistic: statistic
          comparison_operator: operator
          threshold: threshold
        }

        if item.enabled == true
          item.condition = 'on'
          item.ENABLED = _ 'Enabled'
        else
          item.condition = 'off'
          item.ENABLED = _ 'Disabled'
        if item.isSelected == true
          selectedItems.push item
      $scope.selectedItems = selectedItems
      return items

    rulesCallback = (newVal, oldVal) ->
      if newVal != oldVal
        trans newVal

    $scope.$watch('rules', rulesCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    $scope.deleteRule = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        ruleId = item.alarm_id
        $cross.deleteAlarmRule $http, $window, ruleId, (res) ->
          if res == 200
            toastr.success _("Success delete alarm rule: ") + item.name
          else
            toastr.error _("Failed delete alarm rule: ") + item.name
          if index == $scope.selectedItems.length - 1
            setTimeout(() ->
              $state.go('admin.alarm_rule', {}, {reload: true})
            , 100)

    $scope.$on('selected', (event, detail) ->
      if $scope.rules.length > 0
        for rule, index in $scope.rules
          if rule.alarm_id == detail
            rule.isSelected = true
          else
            rule.isSelected = false
      else
        $scope.selectedRuleId = detail
    )

    $scope.editRule = () ->
      ruleId = $scope.singleSelectedItem.alarm_id
      if !ruleId
        return false
      else
        $state.go 'admin.alarm_rule.ruleId.edit', {ruleId: ruleId}

    $scope.refresResource = (resource) ->
      $scope.rulesOpts.data = null
      $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                               $scope.pagingOptions.currentPage)
