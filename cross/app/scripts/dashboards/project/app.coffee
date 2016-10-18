'use strict'

panels = [
  {
    name: _('Overview')
    slug: 'system'
    panels: ['overview']
    single: true
  },
  {
    name: _('Instance')
    slug: 'instance'
    panels: ['instance']
    single: true
  },
  {
    name: _('Volume')
    slug: 'volume'
    panels: ['volume']
    single: true
  },
  {
    name: _('Public network')
    slug: 'public_net'
    panels: ['public_net']
    single: true
  },
  {
    name: _('Image')
    slug: 'image'
    panels: ['image']
    single: true
  },
  {
    name: _('Secret key')
    slug: 'secret_key'
    panels: ['secret_key']
    single: true
  },
  {
    name: _('Security group')
    slug: 'security_group'
    panels: ['security_group']
    single: true
  },
  {
    name: _('Network topology')
    slug: 'net_topology'
    panels: ['net_topology']
    single: true
  },
  {
    name: _('Router')
    slug: 'routers'
    panels: ['routers']
    single: true
  },
  {
    name: _('Network')
    slug: 'networks'
    panels: ['networks']
    single: true
  },
  {
    name: _('Interfaces')
    slug: 'ports'
    panels: ['ports']
    single: true
  },
  {
    name: _('Load Banlancer')
    slug: 'lbaas'
    panels: ['lbaas']
    single: true
  },
  {
    name: _('Operation log')
    slug: 'operation_log'
    panels: ['operation_log']
    single: true
  },
  {
    name: _('Maintenance strategy')
    slug: 'strategy'
    panels: ['strategy']
    single: true
  },
  {
    name: _('Metering')
    slug: 'metering'
    panels: ['metering']
    single: true
  }
]

dashboard =
  slug: 'project'

$cross.registerDashboard(dashboard, panels)
