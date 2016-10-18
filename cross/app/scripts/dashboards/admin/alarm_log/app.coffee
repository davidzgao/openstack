'use strict'

# routes for overview panel
routes = [
  {
    url: '/alarm_log'
    templateUrl: 'views/index.html'
    controller: 'AlarmLogCtr'
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'alarm'
  panel:
    name: _('Alarm Log')
    slug: 'alarm_log'
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
          if roleType == "user_admin"
            return false
        return true
      else
        return false
    else
      return false

$cross.registerPanel(panel, routes)
