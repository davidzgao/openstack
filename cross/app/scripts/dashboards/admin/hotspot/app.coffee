'use strict'

# routes for overview panel
routes =[
  {
    url: '/hotspot'
    templateUrl: 'views/index.html'
    controller: 'HotspotCtr'
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'pool'
  panel:
    name: _('Hotspot monitoring')
    slug: 'hotspot'
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
