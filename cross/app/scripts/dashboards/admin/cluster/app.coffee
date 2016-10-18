'use strict'

# routes for overview panel
routes = [
  {
    url: '/cluster'
    templateUrl: 'views/index.html'
    controller: 'ClustersCtr'
    subStates: [
      {
        url: "/create"
        controller: "ClusterCreateCtr"
        templateUrl: 'views/create.html'
        modal: true
      }
      {
        url: '/:clusterId'
        controller: "ClusterDetailCtr"
        templateUrl: 'views/detail.html'
        subStates: [
          {
            url: '/overview'
            templateUrl: 'views/_detail_overview.html'
          }
          {
            url: '/topology'
            controller: "ClusterTopologyCtr"
            templateUrl: 'views/_detail_topology.html'
          }
        ]
      }
      {
        url: '/:cluId'
        controller: 'ClusterActionCtr'
        templateUrl: 'views/clusterAction.html'
        subStates: [
          {
            url: '/hosts'
            modal: true
            controller: "ClusterHostsCtr"
            templateUrl: 'views/hosts.html'
          }
        ]
      }
    ]
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'pool'
  panel:
    name: _('Cluster')
    slug: 'cluster'
  permissions: (services) ->
    if services\
    and "compute" in services\
    and $CROSS.settings.hypervisor_type == "QEMU"
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
