'use strict'

# routes for flavor panel
routes =[
  {
    url: '/flavor'
    templateUrl: 'views/index.html'
    controller: 'FlavorCtr'
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'instance'
  panel:
    name: 'Flavor'
    slug: 'flavor'
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
