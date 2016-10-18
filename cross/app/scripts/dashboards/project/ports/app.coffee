'use strict'

routes = [
  {
    url: '/ports'
    templateUrl: 'views/index.html'
    controller: 'PortCtr'
    subStates: [{
      url: '/create'
      controller: 'PortCreateCtr'
      modal: true
    }, {
      url: '/:portId'
      templateUrl: '../../../../views/table/detail.html'
      controller: 'PortDetailCtr'
      subStates: [
        {
          url: '/overview'
          templateUrl: 'views/_detail_overview.html'
        }
      ]
    }, {
      url: '/:pId'
      controller: 'portActionCtr'
      templateUrl: 'views/portAction.html'
      subStates: [
        {
          url: '/attach'
          controller: 'attachAction'
          modal: true
        }
        {
          url: '/detach'
          controller: 'detachAction'
          modal: true
        }
      ]
    }]
  }
]

panel =
  dashboard: 'project'
  panelGroup:
    slug: 'ports'
  panel:
    name: 'Ports'
    slug: 'ports'
  permissions: 'network'

$cross.registerPanel(panel, routes)
