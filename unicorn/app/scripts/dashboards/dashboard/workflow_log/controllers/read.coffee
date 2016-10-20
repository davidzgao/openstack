'use strict'

angular.module('Unicorn.dashboard.workflow_log')
  .controller 'dashboard.workflow_log.ReadLogCtr', ($scope, $http, $window,
  $q, $state, $interval) ->

    readTable = new ReadTable()
    readTable.init($scope, {
      $state: $state
      $http: $http
      $window: $window
      $q: $q
    })

    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
    }


class ReadTable extends $unicorn.TableView
  slug: 'readLog'
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
      is_read: 1
      only_admin: 0

    $unicorn.listWorkflowLog $http, $window, $q, queryOpts,
    (logs, total) ->
      callback(logs, total)
