'use strict'

# routes for overview panel
routes =[
  {
    url: '/volume'
    templateUrl: 'views/index.html'
    controller: 'VolumeCtr'
    subStates: [{
      url: '/:volumeId'
      templateUrl: '../../../../views/table/detail.html'
      controller: 'VolumeDetailCtr'
      subStates: [
        {
          url: '/overview'
          controller: 'VolumeOverviewCtr'
          templateUrl: 'views/_detail_overview.html'
        }
      ]
    }, {
      url: '/:volId'
      controller: 'VolumeActionCtrl'
      templateUrl: 'views/_volume_action.html'
      subStates: [
        {
          url: '/attach'
          modal: true
          controller: "VolumeAttachCtrl"
          successState: 'dashboard.volume'
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
    name: 'Volume'
    slug: 'volume'
  permissions: 'compute'

$unicorn.registerPanel(panel, routes)
