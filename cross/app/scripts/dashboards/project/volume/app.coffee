'use strict'

# routes for overview panel
routes =[
  {
    url: '/volume?tab'
    templateUrl: 'views/index.html'
    controller: 'VolumeCtr'
    subStates: [{
      url: '/create'
      controller: 'VolumeCreateCtr'
      modal: true
    }, {
      url: '/:volumeId'
      templateUrl: 'views/detail.html'
      controller: 'VolumeDetailCtr'
      subStates: [
        {
          url: '/overview'
          templateUrl: 'views/_detail_overview.html'
        }
      ]
    }, {
      url: '/:volId'
      controller: 'VolumeActionCtrl'
      templateUrl: 'views/_volume_action.html'
      subStates: [
        {
          url: '/snapshot'
          modal: true
          controller: "SnapshotCreatCtrl"
          successState: 'project.volume'
        }
        {
          url: '/attach'
          modal: true
          controller: "VolumeAttachCtrl"
          successState: 'project.volume'
        }
      ]
    }]
  }
]

panel =
  dashboard: 'project'
  panelGroup:
    slug: 'volume'
  panel:
    name: _('Volume')
    slug: 'volume'
  permissions: 'volume'

$cross.registerPanel(panel, routes)
