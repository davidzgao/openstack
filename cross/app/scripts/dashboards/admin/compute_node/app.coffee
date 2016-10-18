'use strict'

# routes for overview panel
routes = [
  {
    url: '/compute_node'
    templateUrl: 'views/index.html'
    controller: 'HostsCtr'
    subStates: [
      {
        url: '/:hostId/:hostName'
        controller: 'HostDetailCtr'
        templateUrl: 'views/detail.html'
        subStates: [
          {
            url: '/overview'
            templateUrl: 'views/_detail_overview.html'
          }
          {
            url: '/monitor'
            templateUrl: 'views/_detail_monitor.html'
            controller: 'HostMonitorCtr'
          }
        ]
      }
    ]
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'pool'
  panel:
    name: _('Compute Node')
    slug: 'compute_node'
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
