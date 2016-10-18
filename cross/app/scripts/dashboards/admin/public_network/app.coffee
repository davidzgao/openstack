'use strict'

# routes for public_net panel
routes =[
  {
    url: '/public_network'
    templateUrl: 'views/index.html'
    controller: 'PublicNetworkCtr'
    subStates: [{
      url: '/create'
      controller: 'PublicNetworkCreateCtr'
      modal: true
    }]
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'network'
  panel:
    name: _('Public network')
    slug: 'public_network'
  permissions: (projects) ->
    if !projects
      return false
    if "network" in projects
      return false
    else
      return true

$cross.registerPanel(panel, routes)
