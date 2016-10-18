'use strict'

# routes for overview panel
routes =[
  {
    url: '/overview'
    templateUrl: 'views/overview.html'
    controller: 'OverviewCtr'
    subStates: [{
      url: '/createInstance'
      controller: 'project.instance.InstanceCreateCtr'
      import: true
      modal: true
      templateUrl: '../instance/views/_create.html'
      descTemplateUrl: '../instance/views/_create_instance_desc.html'
    }, {
      url: '/createVolume'
      import: true
      controller: 'project.volume.VolumeCreateCtr'
      modal: true
    }, {
      url: '/createFloating'
      import: true
      controller: 'project.public_net.NetAllocateCtr'
      modal: true
    }]
  }
]

panel =
  dashboard: 'project'
  panelGroup:
    slug: 'system'
  panel:
    name: 'Overview'
    slug: 'overview'
  permissions: 'compute'

$cross.registerPanel(panel, routes)
