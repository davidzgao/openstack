'use strict'

angular.module('Cross.admin.workflow_log')
  .controller 'admin.workflow_log.WorkflowLogCtr', ($scope, $http, $window,
  $q, $state, $tabs) ->
    $scope.slug = _ 'Workflow Log'
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
    $tabs $scope, 'admin.workflow_log'

    $scope.sort = {
      sortingOrder: 'generated'
      reverse: true
    }

    $scope.showFooter = true
    $scope.unFristPage = false
    $scope.unLastPage = false

    $scope.refesh = _("Refresh")
    $scope.read = _("Mark as Read")

    $scope.columnDefs = [
      {
        field: "resource_type"
        displayName: _("Application")
        cellTemplate: '<div class="ngCellText enableClick"><a href="#/admin/apply/{{item.traits.resource_id}}/overview">{{item.traits.resource_type|i18n}}</a></div>'
      }
      {
        field: "user_name"
        displayName: _("Applicant")
        cellTemplate: '<div class="ngCellText resource-type" ng-bind="item.user_name"></div>'
      }
      {
        field: "project_name"
        displayName: _("Applicant project")
        cellTemplate: '<div class="ngCellText" ng-bind="item.project_name"></div>'
      }
      {
        field: "generated"
        displayName: _("Application time")
        cellTemplate: '<div class="ngCellText">{{item.generated | dateLocalize | date:"yyyy-MM-dd HH:mm"}}</div>'
      }
    ]
