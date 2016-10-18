'use strict'

# routes for overview panel
routes =[
  {
    url: '/project'
    templateUrl: 'views/index.html'
    controller: 'ProjectsCtr'
    subStates: [
      {
        url: "/create"
        controller: "ProjectCreateCtr"
        templateUrl: 'views/create.html'
        modal: true
      }
      {
        url: '/:projectId'
        controller: 'ProjectActionCtr'
        templateUrl: 'views/projectAction.html'
        subStates: [
          {
            url: '/edit'
            modal: true
            controller: "ProjectEditCtr"
          }
          {
            url: '/member'
            modal: true
            controller: "ProjectMemberCtr"
            templateUrl: 'views/member.html'
          }
          {
            url: '/group'
            modal: true
            controller: "ProjectGroupCtr"
            templateUrl: 'views/group.html'
          }
          {
            url: '/quota'
            modal: true
            controller: "ProjectQuotaCtr"
            templateUrl: 'views/quota.html'
            descTemplateUrl: 'views/projectActionDesc.html'
          }
        ]
      }
      {
        url: '/:projId'
        controller: "ProjectDetailCtr"
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
    slug: 'user'
  panel:
    name: _('Projects')
    slug: 'project'
  permissions: (services) ->
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
      if roleType == "resource_admin"
        return false
    return true

$cross.registerPanel(panel, routes)
