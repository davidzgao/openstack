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
  dashboard: 'admin'
  panelGroup:
    slug: 'system'
  panel:
    name: 'Overview'
    slug: 'overview'
  permissions: 'compute'

$cross.registerPanel(panel, routes)
