'use strict'

# routes for overview panel
routes = [
  {
    url: '/workflow_log'
    templateUrl: 'views/index.html'
    controller: 'WorkflowLogCtr'
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'workflow'
  panel:
    name: _('Workflow Log')
    slug: 'workflow_log'
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
