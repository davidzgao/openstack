'use strict'

# routes for statistic panel
routes = [
  {
    url: '/metering'
    templateUrl: 'views/index.html'
    controller: 'MeteringCtr'
    subStates: [{
      url: "/instanceDetail"
      controller: "InstanceDetailCtr"
      templateUrl: 'views/instanceDetail.html'
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
      }
    ]
  }
]

panel =
  dashboard: 'project'
  panelGroup:
    slug: 'metering'
  panel:
    name: _('Metering')
    slug: 'metering'
  permissions: 'price'

$cross.registerPanel(panel, routes)
