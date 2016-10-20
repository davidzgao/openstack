'use strict'

# routes for overview panel
routes =[
  {
    url: '/log'
    templateUrl: 'views/index.html'
    controller: 'LogCtr'
  }
]

panel =
  dashboard: 'dashboard'
  panelGroup:
    slug: 'helper'
  panel:
    name: 'Log'
    slug: 'log'
  permissions: 'compute'

$unicorn.registerPanel(panel, routes)
