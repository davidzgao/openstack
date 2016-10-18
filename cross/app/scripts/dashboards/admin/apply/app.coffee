'use strict'

# routes for workflow apply panel
routes = [
  {
    url: '/apply?tab'
    templateUrl: 'views/index.html'
    controller: 'ApplyCtr'
    subStates: [
      {
        url: '/approve:data'
        controller: 'approveCtr'
        modal: true
      },
      {
        url: '/reject:data'
        controller: 'rejectCtr'
        modal: true
      },
      {
        url: '/:applyId'
        controller: 'ApplyDetailCtr'
        templateUrl: 'views/detail.html'
        subStates: [
          {
            url: '/overview'
            templateUrl: 'views/_detail_overview.html'
          }
        ]
      }
    ]
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'workflow'
  panel:
    name: _('Apply Process')
    slug: 'apply'
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
