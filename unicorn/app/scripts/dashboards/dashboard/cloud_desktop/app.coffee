'use strict'

# routes for desktop panel.

routes = [
  {
    url: '/cloud_desktop'
    templateUrl: 'views/index.html'
    controller: 'CloudDesktopCtr'
  }
]

panel =
  dashboard: 'dashboard'
  panelGroup:
    slug: 'resource'
  panel:
    name: 'Cloud Desktop'
    slug: 'cloud_desktop'
  permission: 'compute'

$unicorn.registerPanel(panel, routes)
