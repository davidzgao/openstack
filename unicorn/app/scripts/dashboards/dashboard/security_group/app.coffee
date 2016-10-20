'use strict'

# routes for overview panel
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
      templateUrl: '../../../../views/table/detail.html'
      subStates: [
        {
          url: '/overview'
          controller: 'SecGroupOverviewCtr'
          templateUrl: 'views/_detail_overview.html'
        }
      ]
    }]
  }
]

panel =
  dashboard: 'dashboard'
  panelGroup:
    slug: 'resource'
  panel:
    name: 'Security group'
    slug: 'security_group'
  permissions: () ->
    hypervisor_type = $UNICORN.settings.hypervisor_type
    if hypervisor_type == 'VMWARE'
      return false
    else
      return true

$unicorn.registerPanel(panel, routes)
