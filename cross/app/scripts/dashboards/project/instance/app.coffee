'use strict'

# routes for overview panel
routes =[
  {
    url: '/instance?tab'
    templateUrl: 'views/index.html'
    controller: 'InstanceCtr'
    subStates: [{
      url: '/create'
      controller: 'InstanceCreateCtr'
      modal: true
      templateUrl: 'views/_create.html'
      descTemplateUrl: 'views/_create_instance_desc.html'
    }, {
      url: '/:instanceId'
      templateUrl: 'views/detail.html'
      controller: 'InstanceDetailCtr'
      subStates: [
        {
          url: '/overview'
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
          templateUrl: './views/_snapshotCreate.html'
          successState: 'project.instance'
        }
        {
          url: '/resize'
          modal: true
          controller: "ResizeCtrl"
          templateUrl: 'views/_resize.html'
          descTemplateUrl: 'views/_resize_instance_desc.html'
          successState: 'project.instance'
        }
        {
          url: '/bindIp'
          modal: true
          controller: "BindIpCtrl"
          successState: 'project.instance'
        }
        {
          url: '/unbindIp'
          modal: true
          controller: "UnbindIpCtrl"
          successState: 'project.instance'
        }
        {
          url: '/attachVolume'
          modal: true
          controller: "AttachVolumeCtrl"
          successState: 'project.instance'
        }
        {
          url: '/detachVolume'
          modal: true
          controller: "DetachVolumeCtrl"
          successState: 'project.instance'
        }
      ]
    }]
  }
]

panel =
  dashboard: 'project'
  panelGroup:
    slug: 'instance'
  panel:
    name: 'Instance'
    slug: 'instance'
  permissions: 'compute'

$cross.registerPanel(panel, routes)
