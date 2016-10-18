'use strict'

# routes for public_net panel
routes =[
  {
    url: '/security_group'
    templateUrl: 'views/index.html'
    controller: 'SecurityGroupCtr'
    subStates: [{
      url: '/create'
      controller: 'SecurityGroupCreateCtr'
      modal: true
    }, {
      url: '/:securityGroupId'
      controller: 'SecurityGroupDetailCtr'
      templateUrl: 'views/detail.html'
    }]
  }
]

panel =
  dashboard: 'project'
  panelGroup:
    slug: 'security_group'
  panel:
    name: _('Security group')
    slug: 'security_group'
  permissions: (projects) ->
    hypervisor_type = $CROSS.settings.hypervisor_type
    if hypervisor_type == 'VMWARE'
      return false
    else
      return true

$cross.registerPanel(panel, routes)
