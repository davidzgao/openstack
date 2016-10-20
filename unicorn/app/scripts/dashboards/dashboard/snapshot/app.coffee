'use strict'

# routes for overview panel
routes =[
  {
    url: '/snapshot'
    templateUrl: 'views/index.html'
    controller: 'SnapshotCtr'
    subStates: [{
      url: '/:instanceSnapId'
      templateUrl: '../../../../views/table/detail.html'
      controller: 'instanceSnapDetailCtr'
      subStates: [
        {
          url: '/overview1'
          controller: 'instanceSnapOverviewCtr'
          templateUrl: 'views/_detail_overview.html'
        }
      ]
    }]
  }
]

panel =
  dashboard: 'dashboard'
  panelGroup:
    slug: 'resource'
  panel:
    name: 'Snapshot'
    slug: 'snapshot'
  permissions: 'compute'

$unicorn.registerPanel(panel, routes)
