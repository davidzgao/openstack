'use strict'

# routes for overview panel
routes =[
  {
    url: '/instance?tab'
    templateUrl: 'views/index.html'
    controller: 'InstanceCtr'
    subStates: [{
      url: '/:instanceId'
      templateUrl: 'views/detail.html'
      controller: 'InstanceDetailCtr'
      subStates: [
        {
          url: '/overview'
          controller: 'InstanceOverviewCtr'
          templateUrl: 'views/_detail_overview.html'
        }
        {
          url: '/log'
          templateUrl: 'views/_detail_log.html'
          controller: 'InstanceLogCtr'
        }
        {
          url: '/console'
          templateUrl: 'views/_detail_console.html'
          controller: 'InstanceConsoleCtr'
        }
        {
          url: '/monitor'
          templateUrl: 'views/_detail_monitor.html'
          controller: 'InstanceMonitorCtr'
        }
        {
          url: '/topology'
          templateUrl: 'views/_detail_topology.html'
          controller: 'InstanceTopologyCtr'
        }
      ]
    }
    {
      url: '/:instId'
      controller: "InstanceActionCtrl"
      templateUrl: 'views/instanceAction.html'
      subStates: [
        {
          url: '/snapshot'
          modal: true
          controller: "SnapshotCreatCtrl"
        }
        {
          url: '/migrate'
          modal: true
          controller: "MigrateCtrl"
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
    name: 'Instance'
    slug: 'instance'
  permissions: (services) ->
    if services
      if 'compute' in services
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
