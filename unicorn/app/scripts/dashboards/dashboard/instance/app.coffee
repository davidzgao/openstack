'use strict'

# routes for overview panel
routes =[
  {
    url: '/instance?tab'
    templateUrl: 'views/index.html'
    controller: 'InstanceCtr'
    subStates: [{
      url: '/:instanceId'
      templateUrl: '../../../../views/table/detail.html'
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
    },
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
          successState: 'dashboard.instance'
        }
        {
          url: '/resize'
          modal: true
          controller: "ResizeCtrl"
          templateUrl: 'views/_resize.html'
          descTemplateUrl: 'views/_resize_instance_desc.html'
          successState: 'dashboard.instance'
        }
        {
          url: '/bindIp'
          modal: true
          controller: "BindIpCtrl"
          successState: 'dashboard.instance'
        }
        {
          url: '/unbindIp'
          modal: true
          controller: "UnbindIpCtrl"
          successState: 'dashboard.instance'
        }
        {
          url: '/attachVolume'
          modal: true
          controller: "AttachVolumeCtrl"
          successState: 'dashboard.instance'
        }
        {
          url: '/detachVolume'
          modal: true
          controller: "DetachVolumeCtrl"
          successState: 'dashboard.instance'
        }
      ]}
    ]
  }
]

panel =
  dashboard: 'dashboard'
  panelGroup:
    slug: 'resource'
  panel:
    name: 'Instance'
    slug: 'instance'
  permissions: 'compute'

$unicorn.registerPanel(panel, routes)
