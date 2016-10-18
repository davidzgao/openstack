'use strict'

# routes for overview panel
routes = [
  {
    url: '/storage_node'
    templateUrl: 'views/index.html'
    controller: 'StorageCtr'
    subStates: [
      {
        url: '/overview'
        templateUrl: 'views/overview.html'
        controller: 'StorageOverviewCtr'
      }
      {
        url: '/monitor'
        templateUrl: 'views/monitor.html'
        controller: 'StorageMonitorCtr'
      }
    ]
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'pool'
  panel:
    name: _('Storage Node')
    slug: 'storage_node'
  permissions: (services) ->
    if services\
    and "compute" in services\
    and $CROSS.settings.hypervisor_type == "QEMU"
      if $CROSS.person and $CROSS.person.user.roles
        roleList = $CROSS.person.user.roles
        roleType = "admin"
        for role in $CROSS.person.user.roles
          if role.name == "user_admin"
            roleType = role.name
            break
          else if role.name == "resource_admin"
            roleType = role.name
            break
        if roleType == "user_admin"
          return false
      return true
    else
      return false

$cross.registerPanel(panel, routes)
