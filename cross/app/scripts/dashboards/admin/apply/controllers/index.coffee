'use strict'

angular.module('Cross.admin.apply')
  .controller 'admin.apply.ApplyCtr', ($scope, $tabs) ->
    $scope.slug = _ 'Apply'
    $scope.tabs = [{
      title: _('Pending')
      template: 'pending.tpl.html'
      enable: true
      slug: 'pending'
    }, {
      title: _('Reviewed')
      template: 'error.tpl.html'
      enable: true
      slug: 'reviewed'
    }, {
      title: _('Completed')
      template: 'reviewed.tpl.html'
      enable: true
      slug: 'completed'
    }]

    $scope.currentTab = 'pending.tpl.html'
    $tabs $scope, 'admin.apply'
