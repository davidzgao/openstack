'user strict'

angular.module 'Cross.admin.alarm_rule'
  .controller 'admin.alarm_rule.AlarmRuleDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state) ->
    $scope.detailItem = {
      info: _("Detail Info")
      item: {
        name: _("Name")
        id: _("ID")
        status: _("Status")
        created_at: _("Created At")
        owner: _("Creater")
        meter_name: _("Meter Item")
        statistic: _("Statistic Type")
        operator: _("Comparison Operator")
        threshold: _("Threshold")
        severity: _("Severity")
      }
      edit: _("Edit")
      save: _("Save")
      cancel: _("Cancel")
      slug: _("Alarm Rule")
    }
    $scope.currentId = $stateParams.ruleId

    $scope.canEdit = 'btn-disable'
    $scope.inEdit = 'fixed'
    $scope.editing = false

    $scope.selected = {}

    $scope.$watch 'rule_detail', (newVal) ->
      if !newVal
        $scope.canEdit = 'btn-disable'
      else
        $scope.canEdit = 'btn-enable'

    $scope.edit = () ->

      $scope.initialRule = angular.copy($scope.rule_detail)
      if $scope.canEdit == 'btn-disable'
        return false
      if $scope.inEdit == 'fixed'
        $scope.inEdit = 'editing'
        $scope.editing = true
      else
        $scope.inEdit = 'fixed'
        $scope.editing = false
        return
      $scope.selected.operator = {
        value: $scope.rule_detail.threshold_rule.comparison_operator
        text: $scope.rule_detail.operator
      }
      $scope.selected.statistic = {
        value: $scope.rule_detail.threshold_rule.statistic
        text: $scope.rule_detail.statistic
      }
      for severity, name of severityMap
        item = {text: name, value:severity }
        if item.text == $scope.rule_detail.severity
          $scope.severity_value = item.value

      $scope.selected.severity = {
        value: $scope.severity_value
        text:  $scope.rule_detail.severity
      }


    $scope.cancel = () ->
      $scope.nameInValidate = false
      $scope.inEdit = 'fixed'
      $scope.editing = false
      # Restore the origin rule
      $scope.rule_detail = $scope.initialRule

    $scope.save = () ->
      $scope.checkName()
      $scope.checkThreshold()
      if $scope.nameInValidate or $scope.thresholdInValidate
        $scope.checkName()
        $scope.checkThreshold()
      else
        if (typeof $scope.selected.statistic) == 'string'
          selectedStatistic = $scope.selected.statistic
        else
          selectedStatistic = $scope.selected.statistic.value
        if (typeof $scope.selected.operator) == 'string'
          selectedOperator = $scope.selected.operator
        else
          selectedOperator = $scope.selected.operator.value
        if (typeof $scope.selected.severity) == 'string'
          selectedSeverity = $scope.selected.severity
        else
          selectedSeverity = $scope.selected.severity.value
        thresholdRule = $scope.rule_detail.threshold_rule
        alarm_id = $scope.rule_detail.alarm_id
        name = $scope.rule_detail.name
        alarmUpdateParam = {
          alarm_id: alarm_id
          name: name
          severity: selectedSeverity
          threshold_rule:
            meter_name: thresholdRule.meter_name
            statistic: selectedStatistic
            threshold: $scope.rule_detail.threshold
            comparison_operator: selectedOperator
            evaluation_periods: 1
            period: 60
            query: []
          type: 'threshold'
        }
        serverURL = $window.$CROSS.settings.serverURL
        alarmParam = "#{serverURL}/alarm_rule/#{alarm_id}"
        $http.put alarmParam, alarmUpdateParam
          .success (data, status, headers) ->
            $scope.getRule()
            $scope.nameInValidate = false
            $scope.inEdit = 'fixed'
            $scope.editing = false
            toastr.success _("Success update alarm rule: ") + name
          .error (data, status, headers) ->
            toastr.error _("Failed update alarm rule: ") + name
            $scope.nameInValidate = false
            $scope.inEdit = 'fixed'
            $scope.editing = false
            $scope.rule_detail = $scope.initialRule

    $scope.checkThreshold = () ->
      threshold = $scope.rule_detail.threshold
      if threshold
        if not /^[0-9]*$/.test(threshold)
          $scope.thresholdValidata = 'ng-invalid'
          $scope.thresholdInValidate = true
          $scope.thresholdTips = _ "Must be a number."
        else if $scope.rule_detail.thresholdUnit == '%'
          if threshold > 100 or threshold < 0
            $scope.thresholdValidata = 'ng-invalid'
            $scope.thresholdInValidate = true
            $scope.thresholdTips = _ "Must between 0 to 100."
          else
            $scope.thresholdValidata = ''
            $scope.thresholdInValidate = false
        else
          $scope.thresholdValidata = ''
          $scope.thresholdInValidate = false
      else
        $scope.thresholdInvalidate = true
        $scope.thresholdTips = _ "Cannot be empty."

    $scope.checkName = () ->
      name = $scope.rule_detail.name
      if name
        if name.length < 10 or name.length > 40
          $scope.usernameValidate = 'ng-invalid'
          $scope.nameInValidate = true
          $scope.nameTips = _ "Length must between 10 and 40."
        else
          $scope.usernameValidate = ''
          $scope.nameInValidate = false
      else
        $scope.nameInValidate = true
        $scope.nameTips = _ "Cannot be empty."

    $scope.checkSelect = () ->
      $scope.$emit("selected", $scope.currentId)

    $scope.checkSelect()

    $scope.detail_tabs = [
      {
        name: _("Overview"),
        url: 'admin.alarm_rule.ruleId.overview',
        available: true
      }
    ]

    meterMap = $window.$CROSS.alarmMeterItem
    operatorMap = $window.$CROSS.alarmOperator
    statTypeMap = $window.$CROSS.alarmStatType
    severityMap = $window.$CROSS.alarmSeverity

    $scope.getRule = () ->
      $scope.meterItems = []
      $scope.operatorItems = []
      $scope.statTypeItems = []
      $scope.severityItems = []

      $cross.getAlarmRule $http, $window, $scope.currentId, (rule) ->
        for meter, name of meterMap
          item = {text: name, value: meter}
          if rule.threshold_rule.meter_name == meter
            item.selected = true
          $scope.meterItems.push item
        for operator, name of operatorMap
          item = {text: name, value: operator}
          if rule.threshold_rule.comparison_operator == operator
            item.selected = true
          $scope.operatorItems.push item
        for type, name of statTypeMap
          item = {text: name, value: type}
          if rule.threshold_rule.statistic == type
            item.selected = true
          $scope.statTypeItems.push item
        for severity, name of severityMap
          item = {text: name, value:severity }
          if rule.severity == severity
            item.selected = true
          $scope.severityItems.push item

        thresholdRule = rule.threshold_rule
        rule.meter_name = meterMap[thresholdRule.meter_name]
        rule.statistic_type = statTypeMap[thresholdRule.statistic]
        rule.operator = operatorMap[thresholdRule.comparison_operator]
        threshold = thresholdRule.threshold
        rule.severity = severityMap[rule.severity]
        if thresholdRule.meter_name.indexOf('rate') > 0
          rule.threshold = threshold / 1024
          rule.thresholdUnit = 'MB/s'
        else
          rule.threshold = threshold
          rule.thresholdUnit = '%'
        if rule.enabled == true
          rule.statusClass = 'ACTIVE'
          rule.status = _("Enabled")
        else
          rule.statusClass = 'SHUTOFF'
          rule.status = _("Disabled")
        $scope.rule_detail = rule

    $scope.getRule()

    $scope.detailShow = () ->
      container = angular.element('.ui-view-container')
      $scope.detailHeight = $(window).height() - container.offset().top
      $scope.detailHeight -= 50
      $scope.detailWidth = container.width() * 0.78

    if $scope.currentId
      $scope.detail_show = "detail_show"
    else
      $scope.detail_show = "detail_hide"

    $scope.detailShow()

    $scope.checkActive = () ->
      for tab in $scope.detail_tabs
        if tab.url == $state.current.name
          tab.active = 'active'
        else
          tab.active = ''

    $scope.panle_close = () ->
      $state.go 'admin.alarm_rule'
      $scope.detail_show = false

    $scope.checkActive()
