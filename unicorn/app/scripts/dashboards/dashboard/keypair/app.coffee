'use strict'

# routes for overview panel
routes =[
  {
    url: '/keypair'
    templateUrl: 'views/index.html'
    controller: 'KeypairCtr'
    subStates: [{
      url: '/create'
      controller: 'KeypairCreateCtr'
      templateUrl: 'views/_create.html'
      modal: true
    }]
  }
]

panel =
  dashboard: 'dashboard'
  panelGroup:
    slug: 'resource'
  panel:
    name: 'Keypair'
    slug: 'keypair'
  permissions: 'compute'

$unicorn.registerPanel(panel, routes)
