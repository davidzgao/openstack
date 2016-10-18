'use strict'

# routes for overview panel
routes =[
  {
    url: '/operation_log'
    templateUrl: 'views/index.html'
    controller: 'OperationLogCtr'
  }
]

panel =
  dashboard: 'project'
  panelGroup:
    slug: 'operation_log'
  panel:
    name: 'Operation Log'
    slug: 'operation_log'
  permissions: 'compute'

$cross.registerPanel(panel, routes)
