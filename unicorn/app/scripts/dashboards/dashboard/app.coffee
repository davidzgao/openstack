'use strict'

panels = [
  {
    name: _('My Resource')
    slug: 'resource'
    panels: ['overview', 'instance',
             'volume', 'floatingIp', 'routers', 'networks', 'ports',
             'net_topology', 'lbaas', 'snapshot', 'security_group',
             'keypair', 'pricelist']
  },
  {
    name: _('Help and Support')
    slug: 'helper'
    panels: ['application', 'services', 'feedback', 'log', 'workflow_log']
  }
]

dashboard =
  slug: 'dashboard'

$unicorn.registerDashboard(dashboard, panels)
