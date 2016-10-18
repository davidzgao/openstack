'use strict'

# routes for overview panel
routes =[
  {
    url: '/user'
    templateUrl: 'views/index.html'
    controller: 'UsersCtr'
    subStates: [
      {
        url: "/create"
        controller: "UserCreateCtr"
        modal: true
      }
      {
        url: "/:userId"
        controller: "UserDetailCtr"
        templateUrl: 'views/detail.html'
        subStates: [
          {
            url: '/overview'
            templateUrl: 'views/_detail_overview.html'
          }
        ]
      }
      {
        url: "/:uId"
        controller: 'UserProjectCtr'
        templateUrl: 'views/userProject.html'
        subStates: [
          {
            url: '/projects'
            modal: true
            controller: 'UserProjectsManage'
            templateUrl: 'views/userProjectManage.html'
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
    name: _('User')
    slug: 'user'
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
