'use strict'

angular.module('Cross.admin.feedback')
  .controller 'admin.feedback.FeedbackCtr', ($scope, $tabs) ->
    $scope.slug = _ 'Feedback'
    $scope.tabs = [{
      title: _('Untreated')
      template: 'pending.tpl.html'
      enable: true
      slug: 'untreated'
    }, {
      title: _('Processing')
      template: 'processing.tpl.html'
      enable: true
      slug: 'processing'
    }, {
      title: _('Closed')
      template: 'closed.tpl.html'
      enable: true
      slug: 'closed'
    }]

    $scope.currentTab = 'pending.tpl.html'
    $tabs $scope, 'admin.feedback'
