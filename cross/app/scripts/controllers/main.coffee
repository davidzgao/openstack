'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.main', ['ngCookies'])
  .controller 'MainCtrl', ($injector, $scope) ->
    # Get service from $injector.
    $modal         = $injector.get "$modal"
    $http          = $injector.get "$http"
    $q             = $injector.get "$q"
    $rootScope     = $injector.get "$rootScope"
    $gossip        = $injector.get "$gossip"
    $state         = $injector.get "$state"
    $window        = $injector.get "$window"
    $timeout       = $injector.get "$timeout"
    $cookies       = $injector.get "$cookies"
    $cookieStore   = $injector.get "$cookieStore"

    $scope.$on "$destroy", ->
      $gossip.closeConnection()

    $scope.note =
      management: _("Manage")
      project: _("Project")
      message:
        alarm: _("Alarm")
        workflow: _("Workflow")
      logout: _("logout")
      more: _("more")

    $scope.logoHyperLink = $CROSS.settings.hyperLink or\
                           "http://www.hihuron.com"

    $scope.dashboards =
      project: _("Project view")
      admin: _("Admin view")

    MOUSE_DELAY = 70
    # handle actions about message.
    $scope.showMessage = false
    $scope.showLoading = false

    $scope.focusMessage = ->
      if $scope.showMessage
        $scope.showMessage = false
      else
        $scope.showMessage = true
    mouseDelayId = null
    $scope.blurMessage = ->
      if mouseDelayId
        clearTimeout mouseDelayId
      mouseDelayId = $timeout ->
        $scope.showMessage = false
      , MOUSE_DELAY
    serverUrl = $CROSS.settings.serverURL

    $scope.record =
      workflow: 0
      alarm: 0

    _MAX_RECORD_ = 100

    MESSAGE_TADE_TIMEOUT = 5000
    tId = undefined
    # Animate action.
    animateRecordAct = ->
      $scope.animatedRecord = true
      if tId
        clearTimeout tId
      tId = $timeout ->
        $scope.animatedRecord = false
        tId = undefined
      , MESSAGE_TADE_TIMEOUT

    almHistoryHttp = $http.get("#{serverUrl}/resource_alarm_history", {
      params:
        limit: 1
        is_read: 0
    })

    $scope.orient = (state) ->
      name = $state.current.name
      params =
        reload: true
      if name
        split = name.split('.')
        if split.length >= 1 and split[0] == 'admin'
          $state.go state, null, params
        else
          params.inherit = false
          dashboards = $CROSS.dashboards or {}
          viewDashboads = dashboards[view] or []
          $rootScope.$dashboards = viewDashboads
          $rootScope.$view = 'admin'
          $CROSS.view = 'admin'
          $scope.selectedDashboard = $scope.dashboards['admin']
          params.inherit = false
          $scope.showLoading = true
          $http.get "#{serverUrl}/auth?dash=admin"
            .success (person)->
              $CROSS.person = person
              $scope.showLoading = false
              $gossip.closeConnection()
              toastr.clear()
              $state.go state, null, params
            .error (err, status) ->
              $scope.showLoading = false
              if status == 401
                $state.go 'login', null, params
              else
                toastr.error _("Failed to switch to admin dashboard")

    workflowHttp = $http.get("#{serverUrl}/workflow_events", {
      params:
        limit: 1
        is_read: 0
        only_admin: 1
    })
    $q.all([almHistoryHttp, workflowHttp])
    .then (res) ->
      alarm = res[0].data
      workflow = res[1].data
      $scope.record.alarm = alarm.total
      $scope.record.workflow = workflow.total
      if $scope.record.alarm >= _MAX_RECORD_
        $scope.record.alarm = "99+"
      if $scope.record.workflow >= _MAX_RECORD_
        $scope.record.workflow = "99+"
      if alarm.total or workflow.total
        animateRecordAct()

    METER =
      'memory.usage': 'memory usage'
      'cpu_util': 'cpu usage'
      'disk.read.bytes.rate': 'disk read bytes rate'
      'disk.write.bytes.rate': 'disk write bytes rate'
      'network.incoming.bytes.rate': 'network incoming bytes rate'
      'network.outgoing.bytes.rate': 'network outgoing bytes rate'
    OPERATOR =
      'gt': 'greater'
      'lt': 'less'
      'ge': 'greater or equal'
      'le': 'less or equal'
      'eq': 'equal'
      'ne': 'not equal'
    msgRec = (message) ->
      STR = "%(user)s had post a application of %(content)s"
      # handle workflow messages.
      if message.message_type == 'notification'
        if message.tag == 'workflow'
          if $scope.record.workflow != "99+"
            $scope.record.workflow += 1
            if $scope.record.workflow >= _MAX_RECORD_
              $scope.record.workflow = "99+"
          meta = message.meta or {}
          user_id = meta.user_id
          $http.get("#{serverUrl}/users/query", {
            params:
              fields: '["name"]'
              ids   : JSON.stringify([user_id])
          }).success (userDict) ->
            if userDict and userDict[user_id]
              mDict =
                user: userDict[user_id].name
                content: meta.resource_type
              toastr.success _([STR, mDict])

      # handle alarm messages.
      if message.message_type == 'alarm'
        current = message.current
        priority = 'success'
        dict = {}
        if current == 'alarm'
          priority = 'warning'
          dict.state = 'triggered'
        else if current == 'ok'
          priority = 'success'
          dict.state = 'cleared'
        if $scope.record.alarm != "99+"
          $scope.record.alarm += 1
          if $scope.record.alarm >= _MAX_RECORD_
            $scope.record.alarm = "99+"
        reason_data = message.reason_data or {}
        httpReqs = []
        httpReqs.push $http.get "#{serverUrl}/alarm_rule/#{message.alarm_id}"
        resource_name = reason_data.resource_id
        desc = "Alarm is %(state)s as %(statistic)s of " +\
               "%(meter)s is %(comparison)s than %(compare)s in %(interval)s seconds."
        if reason_data and reason_data.resource_type == 'instance'
          params =
            params:
              ids : JSON.stringify([reason_data.resource_id])
              fields: '["name"]'
          httpReqs.push $http.get "#{serverUrl}/servers/query", params
        $q.all(httpReqs).then (res) ->
          res_type = "Hardware"
          if res.length == 2 && reason_data.resource_type == 'instance'
            res_type = "Instance"
            instanceDict = res[1].data
            if instanceDict and instanceDict[reason_data.resource_id]
              resource_name = instanceDict[reason_data.resource_id].name
          alarm = res[0].data
          rule = alarm.threshold_rule
          if not rule
            return false
          dict.statistic = rule.statistic
          dict.meter = METER[rule.meter_name]
          dict.comparison = OPERATOR[rule.comparison_operator]
          dict.compare = rule.threshold
          dict.interval = rule.period
          desc = _(res_type) + resource_name + _([desc, dict])
          toastr[priority](desc)
      $scope.$apply()
      animateRecordAct()

    # handle actions about project.
    $scope.showSelect = false
    defaultView = $CROSS.settings.defaultView
    view = $CROSS.view || defaultView
    dashboards = $CROSS.dashboards || {}
    $rootScope.$dashboards = dashboards[view] || []
    $rootScope.$view = view

    if view == 'admin'
      $scope.selectedDashboard = 'admin'

    $gossip.connect msgRec

    extractRegionInfo = (region) ->
      extra = region.extra or {}
      $CROSS.settings.enable_lbaas = extra.enable_lbaas or false
      $CROSS.settings.enable_ceph = extra.enable_ceph or false
      $CROSS.settings.boot_from_volume = extra.boot_from_volume or false
      for service in region.endpoints
        if service.type == 'network'
          useNeutron = true

      if useNeutron == true
        $CROSS.settings.use_neutron = true
      else
        $CROSS.settings.use_neutron = false

    showProject = ->
      $scope.dash =
        search: ""

      # get project from cookies.
      RECENT_USE_NUMBER = 4
      STORE_KEY_HASH = "crossRecentProjects"
      recProjects = $cookieStore.get(STORE_KEY_HASH)
      recProjects = recProjects || []
      if typeof recProjects == 'string'
        recProjects = JSON.parse recProjects
      $scope.allowedRec = []

      $http.get "#{serverUrl}/regions"
        .success (regions) ->
          $scope.otherRegions = []
          if not regions
            return
          if regions.length > 1
            $scope.multiRegion = 'show'
          for region in regions
            if region.active
              $scope.currentRegion = region
              extractRegionInfo(region)
            else
              $scope.otherRegions.push region

      # get project list.
      $http.get "#{serverUrl}/projects"
        .success (projects) ->
          projects = projects.data
          person = $CROSS.person
          view = $rootScope.$view
          hiddenProjects = $CROSS.settings.hiddenProjects
          allowedRecPros = []
          for pro in recProjects
            break if allowedRecPros.length > RECENT_USE_NUMBER
            for project in projects
              if hiddenProjects and project.name in hiddenProjects
                continue
              # Skip disabled project.
              if not project.enabled || project.enabled == 'false'
                continue
              if pro.id == project.id
                pro.isActive = false
                if person && person.project.id == pro.id && view != 'admin'
                  pro.isActive = true
                allowedRecPros.push pro
                break
          $scope.allowedRec = allowedRecPros
          # store active project.
          $cookieStore.put(STORE_KEY_HASH, JSON.stringify($scope.allowedRec))

          allowProjects = []
          for project in projects
            if hiddenProjects and project.name in hiddenProjects
              continue
            # Skip disabled project.
            if not project.enabled || project.enabled == 'false'
              continue
            item =
              id: project.id
              name: project.name
            if person && person.project.id == project.id && view != 'admin'
              item.isActive = true
            if $scope.allowedRec.length < RECENT_USE_NUMBER
              isIn = false
              for pro in $scope.allowedRec
                if pro.id == project.id
                  isIn = true
                  break
              $scope.allowedRec.push(item) if not isIn
            item.isShow = true
            allowProjects.push item
          $scope.dash.projects = allowProjects
          if projects.length > RECENT_USE_NUMBER
            $scope.enoughProjects = true

          $scope.dash.recProjects = $scope.allowedRec
        .error (err) ->
          toastr.error _("Failed to get projects")

      $scope.searchProjects = ->
        val = $scope.dash.search
        if typeof val == "string"
          val = val.toLowerCase()
        else
          val = ""

        for pro in $scope.dash.projects
          if val == ""
            pro.isShow = true
            continue
          lower = pro.name.toLowerCase()
          if lower.indexOf(val) == -1
            pro.isShow = false
          else
            pro.isShow = true
        return

      $scope.selectedProject = (projectID, projectName) ->
        person = $CROSS.person

        $window.$CROSS.currentProject = projectID
        $scope.showLoading = true
        $http.get "#{serverUrl}/switch/#{projectID}"
          .success (person) ->
            $scope.showLoading = false
            $CROSS.person = person
            $CROSS.view = 'project'
            params =
              reload: true
              inherit: false
              notify: true
            # store recent project info.
            allowedRec = [{
              id: projectID
              name: projectName
            }]
            counter = 0
            for pro in $scope.allowedRec
              break if counter >= RECENT_USE_NUMBER - 1
              if projectID == pro.id
                continue
              item =
                id: pro.id
                name: pro.name
              allowedRec.push item
              counter += 1
            $cookieStore.put(STORE_KEY_HASH, JSON.stringify(allowedRec))
            $gossip.closeConnection()
            toastr.clear()
            $state.go "project.overview", null, params
          .error (err)->
            toastr.error _("Failed to switch to project dashboard")
            $scope.showLoading = false

    $scope.switchRegion = (regionName) ->
      $scope.showLoading = true
      params =
        reload: true
        inherit: false
        notify: true
      $http.post "#{serverUrl}/regions/switch", {region: regionName}
        .success (regions) ->
          $scope.otherRegions = []
          for region in regions
            if region.active
              $scope.currentRegion = region
              extractRegionInfo(region)
            else
              $scope.otherRegions.push region
          $scope.showLoading = false
          # FIXME(ZhengYue): Reload page for load app again
          if location.hash.indexOf('admin') == 2
            location.hash = '#/admin/overview'
          else
            location.hash = '#/project/overview'
          location.reload()
        .error (err) ->
          $scope.showLoading = false
          toastr.error _ (["Failed to switch to %s region", regionName])


    # load project list.
    showProject()
    $scope.changeDashboard = (slug) ->
      dashboards = $CROSS.dashboards || {}
      if slug == "admin"
        viewDashboads = dashboards[view] || []
        $rootScope.$dashboards = viewDashboads
        $rootScope.$view = slug
        $CROSS.view = slug
        $scope.selectedDashboard = $scope.dashboards[slug]
        params =
          reload: true
          inherit: false
          notify: true
        $scope.showLoading = true
        $http.get "#{serverUrl}/auth?dash=admin"
          .success (person)->
            $CROSS.person = person
            $scope.showLoading = false
            $gossip.closeConnection()
            toastr.clear()
            $state.go "admin.overview", null, params
          .error (err, status) ->
            $scope.showLoading = false
            if status == 401
              $state.go 'login', null, params
            else
              toastr.error _("Failed to switch to admin dashboard")
              # TODO(Li Xipeng) go to 400, 401 page

    $scope.showRegions = false
    $scope.multiRegion = 'hidden'
    $scope.selectRegion = ->
      if $scope.otherRegions.length > 0
        $scope.showRegions = true
      else
        $scope.showRegions = false
    $scope.selectDashboard = ->
      if $scope.showSelect
        $scope.showSelect = false
        $scope.hideDash = true
        $scope.dash.show = false
        $scope.hideProjectList = true
        $scope.note.more = _("more")
      else
        $scope.hideDash = false
        $scope.showSelect = true

    delayId = null
    $scope.dashboardBlur = ->
      $scope.hideDash = true
      if delayId
        clearTimeout delayId
      delayId = $timeout ->
        if $scope.hideDash
          delayId = null
          $scope.showSelect = false
          $scope.hideDash = true
          $scope.dash.show = false
          $scope.hideProjectList = true
          $scope.note.more = _("more")
          if !$scope.$$phase
            $scope.$apply()
      , MOUSE_DELAY

    regionDelay = null
    $scope.regionBlur = ->
      if regionDelay
        clearTimeout regionDelay
      regionDelay = $timeout ->
        $scope.showRegions = false
      , MOUSE_DELAY

    $scope.inputFocus = ->
      if delayId
        $scope.hideDash = false
        clearTimeout delayId

    $scope.inputBlur = ->
      $scope.hideDash = true
      if delayId
        clearTimeout delayId
      delayId = $timeout ->
        if $scope.hideDash
          delayId = null
          $scope.dash.show = false
          $scope.showSelect = false
          $scope.hideProjectList = true
          $scope.note.more = _("more")
      , MOUSE_DELAY * 2

    $scope.hideProjectList = true
    $scope.dashMouseEnter = (slug) ->
      if not $scope.hideProjectList
        $scope.dash.show = false
        $scope.hideProjectList = true
        $scope.note.more = _("more")
      else
        $scope.dash.show = true
        $scope.hideProjectList = false
        $scope.note.more = _("Hidden")
    # add by davidzgao,add hide_changeProject_view func
    if $CROSS.person and $CROSS.person.user.roles
      roleType = "admin"
      for role in $CROSS.person.user.roles
        if role.name == "user_admin"
          roleType = role.name
          break
        else if role.name == "resource_admin"
          roleType = role.name
          break
      if roleType == "user_admin" or roleType == "resource_admin"
        $scope.hideChangeProject = true

