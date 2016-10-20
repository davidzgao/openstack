'use strict'

# routes for overview panel
routes =[
  {
    url: '/overview'
    templateUrl: 'views/overview.html'
    controller: 'OverviewCtr'
  }
]

panel =
  dashboard: 'dashboard'
  panelGroup:
    slug: 'resource'
  panel:
    name: 'Overview'
    slug: 'overview'
  permissions: 'compute'

$unicorn.registerPanel(panel, routes)
