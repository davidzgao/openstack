'use strict'

# routes for overview panel
routes = [
  {
    url: '/alarm_rule'
    templateUrl: 'views/index.html'
    controller: 'AlarmRuleCtr'
    subStates: [
      {
        url: '/create'
        controller: 'AlarmRuleCreateCtr'
        templateUrl: 'views/create.html'
        modal: true
      }
      {
        url: '/:ruleId'
        templateUrl: 'views/detail.html'
        controller: 'AlarmRuleDetailCtr'
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
    slug: 'alarm'
  panel:
    name: _('Alarm Rule')
    slug: 'alarm_rule'
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
