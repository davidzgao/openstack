'use strict'

# routes for overview panel
routes =[
  {
    url: '/volume?tab'
    templateUrl: 'views/index.html'
    controller: 'VolumeCtr'
    subStates: [{
      url: '/:volumeId'
      templateUrl: 'views/detail.html'
      controller: 'VolumeDetailCtr'
      subStates: [
        {
          url: '/overview'
          templateUrl: 'views/_detail_overview.html'
        }
      ]
    }]
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'volume'
  panel:
    name: _('Volume')
    slug: 'volume'
  permissions: (services) ->
    if services
      if 'volume' in services
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
