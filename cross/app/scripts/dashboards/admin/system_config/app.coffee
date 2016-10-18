'use strict'

routes = [
  {
    url: '/system_config'
    templateUrl: 'views/index.html'
    controller: 'OptionCtr'
    subStates: [{
      url: '/:optionId'
      controller: 'optionAction'
      templateUrl: 'views/optionAction.html'
      subStates: [
        {
          url: '/edit'
          modal: true
          controller: "optionEditCtr"
        }
      ]
    }]
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'settings'
  panel:
    name: _('System Config')
    slug: 'system_config'
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
          if roleType == "user_admin"
            return false
        return true
      else
        return false
    else
      return false

$cross.registerPanel(panel, routes)
