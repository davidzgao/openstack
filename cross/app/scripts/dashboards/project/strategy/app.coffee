'use strict'

# routes for overview panel
routes =[
  {
    url: '/strategy'
    templateUrl: 'views/index.html'
    controller: 'StrategyCtr'
    subStates: [{
      url: '/:strategyId'
      templateUrl: 'views/detail.html'
      controller: 'StrategyDetailCtr'
    }]
  }
]

panel =
  dashboard: 'project'
  panelGroup:
    slug: 'strategy'
  panel:
    name: _('Strategy')
    slug: 'strategy'
  permissions: 'maintenance'

$cross.registerPanel(panel, routes)
