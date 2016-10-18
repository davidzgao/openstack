'use strict'

# routes for public_net panel
routes =[
  {
    url: '/net_topology'
    templateUrl: 'views/index.html'
    controller: 'NetTopologyCtr'
  }
]

panel =
  dashboard: 'project'
  panelGroup:
    slug: 'net_topology'
  panel:
    name: _('Network topology')
    slug: 'net_topology'
  permissions: 'network'

$cross.registerPanel(panel, routes)
