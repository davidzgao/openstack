'use strict'

# routes for overview panel
routes =[
  {
    url: '/services'
    templateUrl: 'views/index.html'
    controller: 'ServicesCtr'
  }
]

panel =
  dashboard: 'dashboard'
  panelGroup:
    slug: 'helper'
  panel:
    name: 'Services'
    slug: 'services'
  permissions: 'workflow'

$unicorn.registerPanel(panel, routes)
