'use strict'

panels = [
  {
    name: _('Overview')
    slug: 'system'
    panels: ['overview']
    single: true
  },
  {
    name: _('User Manage')
    slug: 'user'
    panels: ['project', 'user']
  },
  {
    name: _('Instance')
    slug: 'instance'
    panels: ['instance', 'flavor', 'image']
  },
  {
    name: _('Volume')
    slug: 'volume'
    panels: ['volume', 'volume_type']
  },
  {
    name: _('Network')
    slug: 'network'
    panels: ['internal_network', 'network', 'public_network']
  },
  {
    name: _('Resource Pool')
    slug: 'pool'
    panels: ['compute_node', 'storage_node', 'hotspot', 'cluster']
  },
  {
    name: _('System Alarm')
    slug: 'alarm'
    panels: ['alarm_rule', 'alarm_log']
  },
  {
    name: _('System Manage')
    slug: 'settings'
    panels: ['info', 'appstore', 'quota', 'system_config']
  },
  {
    name: _('Workflow')
    slug: 'workflow'
    panels: ['apply', 'apply_setting', 'feedback', 'appstore', 'workflow_log']
  },
  {
    name: _('Stat & Metering')
    slug: 'statistic'
    panels: ['statistic','metering','price_make']
  }
]

dashboard =
  slug: 'admin'
  permissions: 'role.admin'

$cross.registerDashboard(dashboard, panels)
