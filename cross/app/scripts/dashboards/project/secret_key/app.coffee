'use strict'

# routes for public_net panel
routes =[
  {
    url: '/secret_key'
    templateUrl: 'views/index.html'
    controller: 'SecretKeyCtr'
    subStates: [{
      url: '/create'
      controller: 'KeypairCreateCtr'
      templateUrl: 'views/_create.html'
      modal: true
    }]
  }
]

panel =
  dashboard: 'project'
  panelGroup:
    slug: 'secret_key'
  panel:
    name: _('Secret key')
    slug: 'secret_key'
  permissions: 'compute'

$cross.registerPanel(panel, routes)
