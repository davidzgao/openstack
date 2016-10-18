'use strict'

# routes for apply setting panel
routes = [
  {
    url: '/apply_setting'
    templateUrl: 'views/index.html'
    controller: 'ApplySettingCtr'
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'workflow'
  panel:
    name: _('Apply Setting')
    slug: 'apply_setting'
  permissions: (services) ->
    if services
      if 'workflow' in services
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
