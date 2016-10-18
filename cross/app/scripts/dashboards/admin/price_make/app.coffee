'use strict'

# routes for statistic panel
routes = [
  {
    url: '/price_make'
    templateUrl: 'views/index.html'
    controller: 'PriceMakeCtr'
    subStates: [
      {
      url: "/priceModify"
      controller: "PriceModifyCtr"
      templateUrl: 'views/priceModify.html'
      modal: true
      }
    ]
  }
]

panel =
  dashboard: 'admin'
  panelGroup:
    slug: 'statistic'
  panel:
    name: _('priceMake')
    slug: 'price_make'
  permissions: (services) ->
    if services
      if 'price' in services
        if $CROSS.person and $CROSS.person.user.roles
          roleList = $CROSS.person.user.roles
          roleType = "admin"
          for role in $CROSS.person.user.roles
            if role.name == "user_admin"
              roleType = role.name
              break
            else if role.name == "resource_admin"
              roleType = role.name
              break
          if roleType != "admin"
            return false
        return true
      else
        return false
    else
      return false

$cross.registerPanel(panel, routes)
