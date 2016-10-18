'use strict'

# routes for statistic panel
routes = [
  {
    url: '/statistic'
    templateUrl: 'views/index.html'
    controller: 'StatisticCtr'
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'statistic'
  panel:
    name: _('Statistic')
    slug: 'statistic'
  permissions: (services) ->
    if services
      if 'metering' in services
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
          if roleType != "admin"
            return false
        return true
      else
        return false
    else
      return false

$cross.registerPanel(panel, routes)
