###*
 # Register panel for specific dashboard.
 #
 # Options of panelView:
 #   `dashboard`: dashboard of panel, such as 'admin'/'project'.
 #   `panelGroup`: panelGroup of this panel.
 #   `panel`: This panel properties.
 #   `permissions`: permissions about whether to show panel.
 #
 # Options of routes is a list, item as:
 #   `url`: url for route.
 #   `templateUrl`: url of template would be used for route.
 #   `controller`: controller would be used for route.
 #
 # @param: {object} Panel options.
 # @routes: {object} routes for this panel.
 #
###
$cross.registerPanel = (panelView, routes)->
  dashboard = panelView.dashboard || "admin"
  panelGroup = panelView.panelGroup
  panel = panelView.panel
  permissions = panelView.permissions

  moduleName = "Cross.#{dashboard}.#{panel.slug}"
  app = angular.module(moduleName, [
    'ngAnimate'
    'ngResource'
    'ui.router'
    'ui.bootstrap'
    'Cross.modal'
  ]).config ($stateProvider, $httpProvider, $modalStateProvider) ->
    cross = window.$CROSS || {}
    window.$CROSS = cross
    isAddPanel = true
    if typeof permissions == "Function" || typeof permissions == "function"
      if not permissions(cross.permissions)
        isAddPanel = false
    else if typeof permissions == "object"
      if cross.permissions
        for permission in permissions
          if permission not in cross.permissions
            isAddPanel = false
            break
    else if typeof permissions == "string"
      if cross.permissions
        if permissions not in cross.permissions
          isAddPanel = false
    if not isAddPanel and cross.permissions
      return

    $CROSS.panels = $CROSS.panels || []
    key = "#{dashboard}.#{panelGroup.slug}.#{panel.slug}"
    $CROSS.panels[key] = panel.name

    if panel.path
      _BASE_URL = "scripts/dashboards/#{dashboard}/#{panel.path}/"
    else
      _BASE_URL = "scripts/dashboards/#{dashboard}/#{panel.slug}/"
    _SLUG_ = "/#{dashboard}"
    $httpProvider.defaults.useXDomain = true
    $httpProvider.defaults.withCredentials = true
    delete $httpProvider.defaults.headers.common['X-Requested-With']
    for route in routes

      _BASE_ = "#{dashboard}.#{panel.slug}"
      url = route.url.replace(/\//g, ".").split('?')[0]
      $stateProvider
        .state "#{dashboard}#{url}",
          url: "#{_SLUG_}#{route.url}"
          templateUrl: "#{_BASE_URL}#{route.templateUrl}"
          controller: "#{_BASE_}.#{route.controller}"
          params: route.params
      if not route.subStates
        continue

      subs = route.subStates
      for sub in subs
        subUrl = sub.url.replace(/\//g, ".").split('?')[0]
        subUrl = subUrl.replace(":", "")
        subLength = subUrl.split('.')
        if subLength.length == 3
          subUrl = '.' + subLength[1] + '/' + subLength[2]
        if sub.modal
          hCls = "class='cross-modal-header'"
          headerTem = "'views/common/_modal_header.html'"
          header = "<div #{hCls} ng-include src=\"#{headerTem}\"></div>"
          cCls = "class='cross-modal-center'"
          centerTem = "'views/common/_modal_fields.html'"
          if sub.templateUrl
            centerTem = "'#{_BASE_URL}#{sub.templateUrl}'"
          larger = false
          if not sub.descTemplateUrl
            center = "<div #{cCls} ng-include src=\"#{centerTem}\"></div>"
          else
            descTem = "'#{_BASE_URL}#{sub.descTemplateUrl}'"
            desCls = "class='cross-modal-des'"
            center = "<div #{cCls} ng-include src=\"#{centerTem}\"></div>" +\
                     "<div #{desCls} ng-include src=\"#{descTem}\"></div>" +\
                     "<div class=\"clear-float\"></div>"
            larger = true
          center += "<div ng-show='modal.modalLoading' class=\"modal-loading\">" +\
                    "<div class=\"backend\"></div>" +\
                    "<div class=\"http-loader__wrapper\">" +\
                    "<div class=\"http-loader\"></div></div></div>"
          successState = sub.successState || '^'
          if sub.import
            subController = "#{sub.controller}"
          else
            subController = "#{_BASE_}.#{sub.controller}"
          $modalStateProvider
            .state "#{dashboard}#{url}#{subUrl}",
              url: "#{sub.url}"
              template: "#{header}#{center}"
              controller: subController
              larger: larger
              successState: successState
              params: sub.params
          continue

        $stateProvider
          .state "#{dashboard}#{url}#{subUrl}",
            url: "#{sub.url}"
            templateUrl: "#{_BASE_URL}#{sub.templateUrl}"
            controller: "#{_BASE_}.#{sub.controller}"
            params: sub.params
        if not sub.subStates
          continue
        for nest in sub.subStates
          nestUrl = nest.url.replace(/\//g, ".").split('?')[0]

          if nest.modal
            hCls = "class='cross-modal-header'"
            headerTem = "'views/common/_modal_header.html'"
            header = "<div #{hCls} ng-include src=\"#{headerTem}\"></div>"
            cCls = "class='cross-modal-center'"
            centerTem = "'views/common/_modal_fields.html'"
            if nest.templateUrl
              centerTem = "'#{_BASE_URL}#{nest.templateUrl}'"
            larger = false
            if not nest.descTemplateUrl
              center = "<div #{cCls} ng-include src=\"#{centerTem}\"></div>"
            else
              descTem = "'#{_BASE_URL}#{nest.descTemplateUrl}'"
              desCls = "class='cross-modal-des'"
              center = "<div #{cCls} ng-include src=\"#{centerTem}\"></div>" +\
                       "<div #{desCls} ng-include src=\"#{descTem}\"></div>" +\
                       "<div class=\"clear-float\"></div>"
              larger = true
            center += "<div ng-show='modal.modalLoading' class=\"modal-loading\">" +\
                      "<div class=\"backend\"></div>" +\
                      "<div class=\"http-loader__wrapper\">" +\
                      "<div class=\"http-loader\"></div></div></div>"
            successState = nest.successState || '^'
            if nest.import
              nestControllerName = "#{nest.controller}"
            else
              nestControllerName = "#{_BASE_}.#{nest.controller}"
            $modalStateProvider
              .state "#{dashboard}#{url}#{subUrl}#{nestUrl}",
                url: "#{nest.url}"
                template: "#{header}#{center}"
                controller: nestControllerName
                larger: larger
                successState: successState
                params: nest.params
            continue

          $stateProvider
            .state "#{dashboard}#{url}#{subUrl}#{nestUrl}",
              url: "#{nest.url}"
              templateUrl: "#{_BASE_URL}#{nest.templateUrl}"
              controller: "#{_BASE_}.#{nest.controller||sub.controller}"
              substate: true
              params: nest.params
    return

###*
 # Register dashboard.
 #
 # Options of panelView:
 #   `dashboard`: dashboard of panel, such as 'admin'/'project'.
 #   `panelGroup`: panelGroup of this panel.
 #   `panel`: This panel properties.
 #   `permissions`: permissions about whether to show panel.
 #
 # Options of routes is a list, item as:
 #   `url`: url for route.
 #   `templateUrl`: url of template would be used for route.
 #   `controller`: controller would be used for route.
 #
 # @param: {object} Panel options.
 # @routes: {object} routes for this panel.
 #
###
$cross.registerDashboard = (dashboardView, panels)->
  permissions = dashboardView.permissions
  moduleName = "Cross.#{dashboardView.slug}"
  panelModules = []
  for panelGroup in panels
    for panel in panelGroup.panels
      panelModules.push("Cross.#{dashboardView.slug}.#{panel}")

  angular.module(moduleName, panelModules).config ->
    cross = window.$CROSS || {}
    window.$CROSS = cross
    window.$CROSS.dashboards = window.$CROSS.dashboards || {}
    window.$CROSS.dashboards[dashboardView.slug] = []
    allPanels = $CROSS.panels || []
    for panelGroup in panels
      group = {
        name: _(panelGroup.name)
        slug: panelGroup.slug
        panels: []
        single: false
      }
      if panelGroup.single
        group.single = panelGroup.single
      panelCount = 0
      loop
        break if panelCount >= panelGroup.panels.length
        panelSlug = panelGroup.panels[panelCount]
        key = "#{dashboardView.slug}.#{panelGroup.slug}.#{panelSlug}"
        if not allPanels[key]
          panelCount += 1
          continue
        group.panels.push({
          name: _(allPanels[key])
          slug: panelSlug
        })
        panelCount += 1
      if group.panels.length
        window.$CROSS.dashboards[dashboardView.slug].push(group)
  return
