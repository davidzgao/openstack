'use strict'

routes = [
  {
    url: '/routers'
    templateUrl: 'views/index.html'
    controller: 'RouterCtr'
    subStates: [{
      url: '/create'
      controller: 'RouterCreateCtr'
      modal: true
    }, {
      url: '/:routerId'
      templateUrl: '../../../../views/table/detail.html'
      controller: 'RouterDetailCtr'
      subStates: [
        {
          url: '/overview'
          templateUrl: 'views/_detail_overview.html'
        }
      ]
    }, {
      url: '/:rId'
      controller: 'routerActionCtr'
      templateUrl: 'views/routerAction.html'
      subStates: [{
        url: '/open'
        controller: 'AddGateway'
        modal: true
      }, {
        url: '/add_port'
        controller: 'AddPort'
        modal: true
      }]
    }]
  }
]

panel =
  dashboard: 'project'
  panelGroup:
    slug: 'routers'
  panel:
    name: 'Routers'
    slug: 'routers'
  permissions: 'network'

$cross.registerPanel(panel, routes)
