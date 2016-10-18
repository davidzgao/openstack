'use strict'

routes = [
  {
    url: '/networks?tab'
    templateUrl: 'views/index.html'
    controller: 'NetworkCtr'
    subStates: [{
      url: '/create'
      controller: 'NetworkCreateCtr'
      modal: true
    }, {
      url: '/:networkId'
      templateUrl: '../../../../views/table/detail.html'
      controller: 'NetworkDetailCtr'
      subStates: [
        {
          url: '/overview'
          templateUrl: 'views/_detail_overview.html'
        }
      ]
    }, {
      url: '/:nId'
      controller: 'networkActionCtr'
      templateUrl: 'views/networkAction.html'
      subStates: [
        {
          url: '/attach'
          controller: 'attachAction'
          modal: true
        }
        {
          url: '/createsubnet'
          controller: 'createSubAction'
          modal: true
        }
      ]
    }]
  }
]

panel =
  dashboard: 'project'
  panelGroup:
    slug: 'networks'
  panel:
    name: 'Networks'
    slug: 'networks'
  permissions: 'network'

$cross.registerPanel(panel, routes)
