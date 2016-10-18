'use strict'

# routes for public_net panel
routes =[
  {
    url: '/public_net'
    templateUrl: 'views/index.html'
    controller: 'PublicNetCtr'
    subStates: [{
      url: '/allocate'
      controller: 'NetAllocateCtr'
      modal: true
    }, {
      url: '/:floatingIpId'
      controller: 'FloatingIpActionCtrl'
      templateUrl: 'views/_floating_ip_action.html'
      subStates: [
        {
          url: '/bind'
          modal: true
          controller: "FloatingIpBindCtrl"
          successState: 'project.public_net'
        }]
    }]
  }
]

panel =
  dashboard: 'project'
  panelGroup:
    slug: 'public_net'
  panel:
    name: _('Public network')
    slug: 'public_net'
  permissions: 'compute'

$cross.registerPanel(panel, routes)
