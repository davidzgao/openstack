'use strict'
angular.module 'Cross.admin.alarm_rule'
  .controller 'admin.alarm_rule.AlarmRuleCreateCtr', ($scope, $http,
  $window, $q, $state, $log) ->
    $scope.slug = _ 'Alarm Rule'
    (new RuleCreateModal()).initial($scope,
      {
        $http: $http
        $window: $window
        $q: $q
        $state: $state
        $log: $log
      })
    $scope.form['statistic_type'] = 'avg'
    meterMap = $window.$CROSS.alarmMeterItem
    operatorMap = $window.$CROSS.alarmOperator
    statTypeMap = $window.$CROSS.alarmStatType
    severityMap = $window.$CROSS.alarmSeverity

    meterItems = []
    operatorItems = []
    statTypeItems = []
    severityItems = []

    for meter, name of meterMap
      item = {text: name, value: meter}
      meterItems.push item
    for operator, name of operatorMap
      item = {text: name, value: operator}
      operatorItems.push item
    for type, name of statTypeMap
      item = {text: name, value: type}
      statTypeItems.push item
    for severity, name of severityMap
      item = {text: name, value: severity}
      severityItems.push item

    # Set default value for select
    $scope.modal.fields[1].default = meterItems
    $scope.modal.fields[2].default = statTypeItems
    $scope.modal.fields[3].default = operatorItems
    $scope.modal.fields[4].default = severityItems

    $scope.form['meter_item'] = 'cpu_util'
    $scope.thresholdUnit = '%'
    $scope.form['operator'] = 'gt'
    $scope.form['severity'] = 'low'

    $scope.$watch 'form', (newVal, oldVal) ->
      if newVal.meter_item != oldVal.meter_item
        meterItem = meterMap[newVal.meter_item]
        name = "#{meterItem}#{$scope.slug}"
        $scope.form['name'] = name
        if newVal.meter_item.indexOf('.rate') > 0
          $scope.thresholdUnit = 'MB/s'
        else
          $scope.thresholdUnit = '%'
        $scope.modal.fields[5].placeholder = $scope.thresholdUnit
    , true

    $scope.form['name'] = "#{meterMap[$scope.form['meter_item']]}#{$scope.slug}"
    $scope.form['enabled'] = [true]

class RuleCreateModal extends $cross.Modal
  title: _ "Create Alarm Rule"
  slug: 'create_rule'
  single: true
  parallel: true

  fields: ->
    [
      {
        slug: 'name'
        label: _("Alarm Rule Name")
        tag: 'input'
        restrictions:
          required: false
          len: [8, 40]
      }
      {
        slug: 'meter_item'
        label: _('Meter Item')
        tag: 'select'
        default: []
        restrictions:
          required: true
      }
      {
        slug: 'statistic_type'
        label: _('Statistic Type')
        tag: 'select'
        default: []
        restrictions:
          required: true
      }
      {
        slug: 'operator'
        label: _('Comparison Operator')
        tag: 'select'
        default: [
        ]
        restrictions:
          required: true
      }
      {
        slug: 'severity'
        label: _('Severity')
        tag: 'select'
        default: []
        restrictions :
          required: true
      }
      {
        slug: 'threshold'
        label: _('Threshold')
        tag: 'input'
        placeholder: '%'
        restrictions:
          required: true
          number: true
      }
      {
        slug: 'enabled'
        label: _('Enable')
        tag: 'input'
        type: "checkbox-list"
        default: [{text: _(""), value: true}]
        restrictions:
          required: false
      }
    ]

  handle: ($scope, options) ->
    param = $scope.form
    alarmServerURL = options.$window.$CROSS.settings.alarmServerURL
    $log = options.$log
    if !alarmServerURL
      $log.error("Configuration Error: Please set alarmServerURL
         option at config file!")
    alarmActionURL = "#{alarmServerURL}callback/alarm"
    okActionURL = "#{alarmServerURL}callback/ok"
    enabled = true
    if param.enabled.length == 0
      enabled = false

    if param.meter_item.indexOf('.rate') > 0
      param.threshold = parseInt(param.threshold) * 1024

    alarmCreateParam = {
      alarm_actions: [alarmActionURL]
      ok_actions: [okActionURL]
      name: param.name
      threshold_rule:
        meter_name: param.meter_item
        statistic: param.statistic_type
        threshold: parseInt(param.threshold)
        comparison_operator: param.operator
        evaluation_periods: 1
        period: 60
        query: []
      type: 'threshold'
      severity: param.severity
      enabled: enabled
    }

    serverURL = options.$window.$CROSS.settings.serverURL
    alarmParam = "#{serverURL}/alarm_rule"
    options.$http.post alarmParam, alarmCreateParam
      .success (data, status, headers) ->
        toastr.success _("Success create alarm rule: ") + param.name
      .error (data, status, headers) ->
        toastr.error _("Failed create alarm rule: ") + param.name

    options.$state.go 'admin.alarm_rule', {}, {reload: true}
