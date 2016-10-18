'use strict'

# routes for overview panel
routes =[
  {
    url: '/image'
    templateUrl: 'views/index.html'
    controller: 'ImageCtr'
    subStates: [{
      url: '/create'
      controller: 'ImageCreateCtr'
      modal: true
      templateUrl: 'views/_create.html'
    }, {
      url: '/:imageId'
      templateUrl: 'views/detail.html'
      controller: 'ImageDetailCtr'
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
    slug: 'instance'
  panel:
    name: _('Image')
    slug: 'image'
  permissions: (services) ->
    if services
      if 'image' in services
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
