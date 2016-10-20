'use strict'

routes =[
  {
    url: '/pricelist'
    templateUrl: 'views/index.html'
    controller: 'PricelistCtr'
    subStates: [{
      url: '/instanceDetail'
      templateUrl: 'views/instanceDetail.html'
      controller: 'InstanceDetailCtr'
      params: {
        "service": "",
        "name": "",
        "cpus": "",
        "run_time": "",
        "mem": "",
        "disk": "",
        "size": ""
      }
      modal: true
    }]
  }
]

panel =
  dashboard: 'dashboard'
  panelGroup:
    slug: 'resource'
  panel:
    name: 'Pricelist'
    slug: 'pricelist'
  permissions: 'price'

$unicorn.registerPanel(panel, routes)
