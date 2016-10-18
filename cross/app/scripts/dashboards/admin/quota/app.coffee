'use strict'

# routes for overview panel
routes =[
  {
    url: '/quota'
    templateUrl: 'views/index.html'
    controller: 'QuotaCtr'
    subStates: [
      {
        url:'/create'
        controller: 'QuotaCreateCtr'
        templateUrl: 'views/create.html'
        modal: true
      }
    ]
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'settings'
  panel:
    name: _('System Quota')
    slug: 'quota'
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
