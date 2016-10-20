'use strict'

# routes for overview panel
routes = [{
    url: '/feedback?tab'
    templateUrl: 'views/index.html'
    controller: 'FeedbackCtr'
    subStates: [{
      url: '/create'
      controller: 'FeedbackCreateCtr'
      modal: true
    }, {
      url: '/:feedbackId'
      controller: 'FeedbackDetailCtr'
      templateUrl: '../../../../views/table/detail.html'
      subStates: [{
        url: '/overview'
        controller: 'feedbackOverviewCtr'
        templateUrl: 'views/_detail_overview.html'
      }, {
        url: '/reply'
        controller: 'feedbackReplyCtr'
        templateUrl: 'views/_detail_reply.html'
      }]
    }]
}]

panel =
  dashboard: 'dashboard'
  panelGroup:
    slug: 'helper'
  panel:
    name: 'Feedback'
    slug: 'feedback'
  permissions: 'compute'

$unicorn.registerPanel(panel, routes)
