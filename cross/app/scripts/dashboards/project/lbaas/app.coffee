'use strict'

routes = [
  {
    url: '/lbaas'
    templateUrl: 'views/index.html'
    controller: 'LBCtr'
    subStates: [{
      url: '/create'
      controller: 'LBCreateCtr'
      modal: true
    }, {
      url: '/:lbId'
      templateUrl: '../../../../views/table/detail.html'
      controller: 'LBDetailCtr'
      subStates: [
        {
          url: '/overview'
          templateUrl: 'views/_detail_overview.html'
        }
      ]
    }, {
      url: '/:LBId'
      controller: 'lbActionCtr'
      templateUrl: 'views/lbAction.html'
      subStates: [
        {
          url: '/vip'
          controller: 'vipAction'
          modal: true
        }
        {
          url: '/member'
          controller: 'memberAction'
          modal: true
          templateUrl: '../../../../views/member.html'
        }
      ]
    }]
  }
]

panel =
  dashboard: 'project'
  panelGroup:
    slug: 'lbaas'
  panel:
    name: 'LBaaS'
    slug: 'lbaas'
  permissions: () ->
    if $CROSS.settings.use_neutron and $CROSS.settings.enable_lbaas
      return true
    else
      return false

$cross.registerPanel(panel, routes)
