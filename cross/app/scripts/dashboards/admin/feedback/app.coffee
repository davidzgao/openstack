'use strict'

# routes for feedback panel
routes = [
  {
    url: '/feedback?tab'
    templateUrl: 'views/index.html'
    controller: 'FeedbackCtr'
    subStates: [
      {
        url: '/:feedId'
        controller: 'FeedbackDetailCtr'
        templateUrl: 'views/detail.html'
        subStates: [
          {
            url: '/overview'
            controller: 'FeedbackOverviewCtr'
            templateUrl: 'views/_detail_overview.html'
          }
          {
            url: '/reply'
            controller: 'FeedbackReplyCtr'
            templateUrl: 'views/_detail_reply.html'
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
    name: _('Feedback')
    slug: 'feedback'
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
