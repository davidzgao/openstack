'use strict'

# routes for net_topology panel
routes = [
  {
    url: '/net_topology'
    templateUrl: 'views/index.html'
    controller: 'NetTopologyCtr'
  }
]

panel =
  dashboard: 'dashboard'
  panelGroup:
    slug: 'resource'
  panel:
    name: 'Network Topology'
    slug: 'net_topology'
  permissions: 'network'

$unicorn.registerPanel(panel, routes)
