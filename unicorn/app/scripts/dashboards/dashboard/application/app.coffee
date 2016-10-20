'use strict'

# routes for overview panel
routes =[
  {
    url: '/application?tab'
    templateUrl: 'views/index.html'
    controller: 'ApplicationCtr'
    subStates: [
      {
        url: '/:applyId'
        controller: 'ApplyDetailCtr'
        templateUrl: '../../../../views/table/detail.html'
        subStates: [
          {
            url: '/overview'
            controller: 'applyOverviewCtr'
            templateUrl: 'views/_detail_overview.html'
          }
        ]
      }
      {
        url: '/:errorApplyId'
        controller: 'ErrorDetailCtr'
        templateUrl: '../../../../views/table/detail.html'
        subStates: [
          {
            url: '/overview'
            controller: 'errorOverviewCtr'
            templateUrl: 'views/_detail_overview.html'
          }
        ]
      }
      {
        url: '/:reviewedApplyId'
        controller: 'ReviewedDetailCtr'
        templateUrl: '../../../../views/table/detail.html'
        subStates: [
          {
            url: '/overview'
            controller: 'reviewedOverviewCtr'
            templateUrl: 'views/_detail_overview.html'
          }
        ]
      }
    ]
  }
]

panel =
  dashboard: 'dashboard'
  panelGroup:
    slug: 'helper'
  panel:
    name: 'Application'
    slug: 'application'
  permissions: 'workflow'

$unicorn.registerPanel(panel, routes)
