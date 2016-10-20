'use strict'

# routes for overview panel
routes =[
  {
    url: '/floatingIp'
    templateUrl: 'views/index.html'
    controller: 'FloatingIpCtr'
    subStates: [{
      url: '/:floatingIpId'
      controller: 'FloatingIpActionCtrl'
      templateUrl: 'views/_floating_ip_action.html'
      subStates: [
        {
          url: '/bind'
          modal: true
          controller: "FloatingIpBindCtrl"
          successState: 'dashboard.floatingIp'
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
    name: 'Floating IP'
    slug: 'floatingIp'

$unicorn.registerPanel(panel, routes)
