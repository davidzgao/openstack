'use strict'

# routes for overview panel
routes = [
  {
    url: '/workflow_log'
    templateUrl: 'views/index.html'
    controller: 'WorkflowLogCtr'
  }
]

panel =
  dashboard: 'dashboard'
  panelGroup:
    slug: 'helper'
  panel:
    name: _('Workflow Log')
    slug: 'workflow_log'
  permissions: ['metering']

$unicorn.registerPanel(panel, routes)
