'use strict'

# routes for public_net panel
routes =[
  {
    url: '/internal_network'
    templateUrl: 'views/index.html'
    controller: 'InternalNetworkCtr'
    subStates: [{
      url: '/create'
      controller: 'InternalNetworkCreateCtr'
      modal: true
    }]
  }
]

neutron_routes = [
  {
    url: '/network?tab'
    templateUrl: 'views/neutronIndex.html'
    controller: 'NetworkCtr'
    subStates: [{
      url: '/create'
      controller: 'NetworkCreateCtr'
      modal: true
    }, {
      url: '/:networkId'
      templateUrl: '../../../../views/table/detail.html'
      controller: 'NetworkDetailCtr'
      subStates: [
        {
          url: '/overview'
          templateUrl: 'views/_detail_overview.html'
        }
      ]
    }, {
      url: '/:nId'
      controller: 'networkActionCtr'
      templateUrl: 'views/networkAction.html'
      subStates: [
        {
          url: '/attach'
          controller: 'attachAction'
          modal: true
        }
        {
          url: '/createsubnet'
          controller: 'createSubAction'
          modal: true
        }
      ]
    }]
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'network'
  panel:
    name: _('Internal network')
    slug: 'internal_network'
  permissions: () ->
    if $CROSS.settings.use_neutron == true
      return false
    else
      return true

neutron_panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'network'
  panel:
    name: _('Network')
    slug: 'network'
    path: 'internal_network'
  permissions: (services) ->
    if services\
    and "network" in services
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
    return

#if $CROSS.settings.use_neutron == true
#  panel.permissions = () ->
#    return false
#else
#  panel.permissions = () ->
#    return true
$cross.registerPanel(neutron_panel, neutron_routes)
$cross.registerPanel(panel, routes)
