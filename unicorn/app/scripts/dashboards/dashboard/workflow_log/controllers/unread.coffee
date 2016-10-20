'use strict'

angular.module('Unicorn.dashboard.workflow_log')
  .controller 'dashboard.workflow_log.UnreadLogCtr', ($scope, $http, $window,
  $q, $state, $interval) ->

    $scope.selectedItems = []
    $scope.readEnableClass = 'btn-disable'

    $scope.selectChange = () ->
      if $scope.selectedItems.length >= 1
        $scope.readEnableClass = 'btn-enable'
      else
        $scope.readEnableClass = 'btn-disable'
    unreadTable = new UnreadTable()
    unreadTable.init($scope, {
      $state: $state
      $http: $http
      $window: $window
      $q: $q
    })

    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      buttons: [
        {
          type: 'single'
          tag: 'button'
          name: 'edit'
          verbose: _("Mark as Read")
          action: $scope.readLog
          enable: false
          restrict:
            batch: true
          needConfirm: true
        }
      ]
    }


class UnreadTable extends $unicorn.TableView
  slug: 'unreadLog'
  columnDefs: [
    {
      field: "resource_type"
      displayName: _("Application")
      cellTemplate: '<div class="ngCellText enableClick"><a href="#/dashboard/application/{{item.traits.resource_id}}/overview">{{item.traits.resource_type|i18n}}</a></div>'
    }
    {
      field: "user_name"
      displayName: _("Applicant")
      cellTemplate: '<div class="ngCellText resource-type" ng-bind="item.user_name"></div>'
    }
    {
      field: "state"
      displayName: _("State")
      cellTemplate: '<div class="ngCellText resource-type">{{item.state|i18n}}</div>'
    }
    {
      field: "generated"
      displayName: _("Application time")
      cellTemplate: '<div class="ngCellText">{{item.generated | dateLocalize | date:"yyyy-MM-dd HH:mm"}}</div>'
    }
  ]
  listData: ($scope, options, dataQueryOpts, callback) ->
    $http = options.$http
    $q = options.$q
    $window = options.$window
    queryOpts =
      skip: dataQueryOpts.dataFrom
      limit: dataQueryOpts.dataTo - dataQueryOpts.dataFrom
      is_read: 0
      only_admin: 0

    $unicorn.listWorkflowLog $http, $window, $q, queryOpts,
    (logs, total) ->
      console.log(logs, total)
      callback(logs, total)

  judgeAction: (action, selectedItems) ->
    restrict = {
      batch: true
    }
    for key, value of action.restrict
      restrict[key] = value
    if selectedItems.length == 0
      action.enable = false
      return
    else
      action.enable = true

  itemChange: (newVal, oldVal, $scope, options) ->
    super newVal, oldVal, $scope, options
    obj = options.$this

    if !$scope.actionButtons
      return
    for action in $scope.actionButtons.buttons
      if !action.restrict
        continue
      obj.judgeAction(action, $scope.selectedItems)

  initialAction: ($scope, options) ->
    super $scope, options

    obj = options.$this
    $http = options.$http
    $window = options.$window
    $state = options.$state

    $scope.readLog = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        logId = item.message_id
        $unicorn.readWorkflowLog $http, $window, logId, () ->
          toastr.success _("Success mark workflow log as read!")
          $state.go "dashboard.workflow_log", {}, {reload: true}
