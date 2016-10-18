'use strict'

# routes for statistic panel
routes = [
  {
    url: '/metering'
    templateUrl: 'views/index.html'
    controller: 'MeteringCtr'
    subStates: [{
      url: "/instanceDetail"
      controller: "InstanceDetailCtr"
      templateUrl: 'views/instanceDetail.html'
      params: {
                "service": "",
                "name": "",
                "cpus": "",
                "run_time": "",
                "mem": "",
                "disk": "",
                "size": ""
              }
      modal: true
      }
    ]
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'statistic'
  panel:
    name: _('Metering')
    slug: 'metering'
  #permissions: 'price'  
  permissions: (services) ->
    if services
      if 'price' in services
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
