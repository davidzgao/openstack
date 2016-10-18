'use strict'

# routes for overview panel
routes =[
  {
    url: '/info'
    templateUrl: 'views/index.html'
    controller: 'InfoCtr'
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'settings'
  panel:
    name: _('System Info')
    slug: 'info'
  permissions: (services) ->
    if services
      if 'compute' in services
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
    else
      return false

$cross.registerPanel(panel, routes)
