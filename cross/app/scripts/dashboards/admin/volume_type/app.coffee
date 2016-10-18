'use strict'

# routes for overview panel
routes =[
  {
    url: '/volume_type'
    templateUrl: 'views/index.html'
    controller: 'VolumeTypeCtr'
    subStates: [{
      url: "/create"
      controller: "VolumeTypeCreateCtr"
      modal: true
    }]
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'volume'
  panel:
    name: _('Volume Type')
    slug: 'volume_type'
  permissions: (services) ->
    if $CROSS.settings.useVolumeType \
    and $CROSS.settings.useVolumeType.toLocaleLowerCase() == "true"
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
