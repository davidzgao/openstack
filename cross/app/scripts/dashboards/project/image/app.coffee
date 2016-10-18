'use strict'

# routes for overview panel
routes =[
  {
    url: '/image?tab'
    templateUrl: 'views/index.html'
    controller: 'ImageCtr'
    subStates: [{
      url: '/create'
      controller: 'ImageCreateCtr'
      modal: true
      templateUrl: 'views/_create.html'
    }, {
      url: '/:imageId'
      templateUrl: 'views/detail.html'
      controller: 'ImageDetailCtr'
      subStates: [
        {
          url: '/overview'
          templateUrl: 'views/_detail_overview.html'
        }
      ]
    }]
  }
]

panel =
  dashboard: 'project'
  panelGroup:
    slug: 'image'
  panel:
    name: _('Image')
    slug: 'image'
  permissions: 'image'

$cross.registerPanel(panel, routes)
