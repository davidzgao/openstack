'use strict'

angular.module 'Cross.admin.statistic'
  .controller 'admin.statistic.StatisticCtr', ($scope, $http, $window,
  $q, $state, $interval, $stateParams ,$tabs, stringToDatetime) ->
    $scope.tabs = [
      {
        title: _('Instance')
        template: 'instance.tpl.html'
        enable: true
      }
      {
        title: _('Volume')
        template: 'volume.tpl.html'
        enable: true
      }
    ]

    serverUrl = $window.$CROSS.settings.serverURL

    $scope.currentTab = 'instance.tpl.html'

    $tabs $scope, 'admin.statistic'

    $scope.note = {
      projectName: _("Project Name")
      projectId: _("Project ID")
      query: _("Query")
      export: _("Export")
      cpuUsage: _("CPU Hours")
      memUsage: _("RAM Hours(GB*Hour)")
      diskUsage: _("Disk Hours(GB*Hour)")
      instancesTotalUsage: _("Instances Uptime(Hour)")
      volumesTotalUsage: _("Volumes Uptime(GB*Hour)")
      instancesDetailUsage: _("Detail usage of instances")
      volumesDetailUsage: _("Detail usage of volumes")
      usagenull: _("Temporarily no statistic data!")
      all: _("ALL")
      export_all: _("Export All")
      resource_name: _('Resource name')
      vcpus: _('CPU(Core)')
      memory_mb: _('Memory(MB)')
      root_gb: _('Disk(GB)')
      run_time: _('Uptime (Hour)')
      size: _('Disk(GB)')
    }
    $scope.instancesTableTop = ['resource_name', 'vcpus', 'memory_mb', 'root_gb', 'run_time']
    $scope.volumesTableTop = ['resource_name', 'size', 'run_time']
    # NOTE(liuhaobo): Add the function of exportAll and exportData
    $scope.exportAll = () ->
      setTimeout(() ->
        argId = "all_project_statistic"
        exp = new Blob([document.getElementById(argId).innerText],
        {
          type: ".csv;charset=utf-8"
        })
        saveAs(exp, "Report_all_projects.csv")
      , 2000)

    $scope.exportData = (ind) ->
      # Function for export datatable as .xls file
      for project, index in $scope.projectReprs
        if index == ind
          argId = "project_#{project.tenant_id}_statistic"
          exp = new Blob([document.getElementById(argId).innerText],
          {
            "type": ".csv;charset=utf-8"
          })
          saveAs(exp, "Report_#{project.tenant_id}.csv")
          break
        else
          continue

    # Variate used for statistic query
    $scope.query = {}
    monthNames = [ _("January"), _("February"), _("March"),
                   _("April"), _("May"), _("June"), _("July"),
                   _("August"), _("September"), _("October"),
                   _("November"), _("December")]
    getDateList = () ->
      # Get latest 4 years and sort month by current month at first
      date = new Date()
      yearList = []
      currentYear = date.getFullYear()
      currentMonth = date.getMonth()
      $scope.currentYear = currentYear
      $scope.currentMonth = currentMonth
      months = []
      for month, index in monthNames
        months.push {index: index, name: month}
      $scope.monthNames = months
      yearList.push currentYear
      yearList.push (currentYear - 1)
      yearList.push (currentYear - 2)
      yearList.push (currentYear - 3)
      $scope.yearList = yearList

    getDateList()
    $scope.query.year = $scope.yearList[0]
    $scope.query.month = $scope.monthNames[$scope.currentMonth]

    getQuery = () ->
      # Get start and end for statistic query
      month = $scope.query.month.index
      if typeof($scope.query.month) == 'string'
        month = parseInt($scope.query.month)
      year = $scope.query.year
      if typeof(year) == 'string'
        year = $scope.yearList[parseInt(year)]
      firstDay = new Date(year, month, 1)
      firstDay.setUTCHours(24)
      firstDay = firstDay.toISOString()
      firstDay = firstDay.substr(0, 23)
      lastDay = new Date(year, month + 1, 0, 16)
      lastDay.setUTCHours(24)
      lastDay = lastDay.toISOString()
      lastDay = lastDay.substr(0, 23)
      $scope.queryDate = "#{year} #{$scope.monthNames[month].name}"
      if month == $scope.currentMonth and year == $scope.currentYear
        lastDay = new Date().toISOString()
        lastDay = lastDay.substr(0, 23)
      project = $scope.query.project
      if project.tenant_id != 0
        projectId = project.tenant_id

      return [firstDay, lastDay, projectId]

    $scope.projectList = []
    $scope.projectList.push {project_name: _ 'ALL', id: 0}
    $scope.query.project = $scope.projectList[0]
    param = "?q.field=event_type&q.op=eq&q.value=compute.instance.create.end"
    getProjectsForQueryInstance = () ->
      $cross.getProjectList($http, $window, $q, (projectList) ->
        for project in projectList
          if project.project_name.length > 26
            project.project_name = project.project_name.substr(0, 26)
        $scope.projectList = $scope.projectList.concat projectList

      )
    getProjectsForQueryInstance()

    getSearchDate = (endAt) ->
      endAtSecond = new Date(Date.parse(endAt))
      searchStart = new Date(endAtSecond.getFullYear(),\
                             endAtSecond.getMonth(), \
                             endAtSecond.getDate(), \
                             endAtSecond.getHours())
      searchEnd = new Date(endAtSecond.getFullYear(), \
                           endAtSecond.getMonth(), \
                           endAtSecond.getDate(), \
                           endAtSecond.getHours() + 1)
      searchStart = searchStart.toISOString().substr(0, 23)
      searchEnd = searchEnd.toISOString().substr(0, 23)

      return [searchStart, searchEnd]

    # NOTE(liuhaobo): get the statistic info when click on tab
    $scope.getTabStatistic = (type) ->
      $scope.loading = true
      $scope.query.project = $scope.projectList[0] if type == "tab"
      query = getQuery()
      startAt = query[0]
      endAt = query[1]
      searchDate = getSearchDate(endAt)
      searchStart = searchDate[0]
      searchEnd = searchDate[1]

      param = "?q.field=event_type&q.op=eq&q.value=compute.instance.create.end\
               &q.field=start_timestamp&q.value=#{startAt}&q.field=end_timestamp&q.value=#{endAt}"
      paramDel = "?q.field=event_type&q.op=eq&q.value=compute.instance.delete.end\
                  &q.field=start_timestamp&q.value=#{startAt}&q.field=end_timestamp&q.value=#{endAt}"
      paramExist = "?q.field=event_type&q.op=eq&q.value=compute.instance.exists\
               &q.field=start_timestamp&q.value=#{searchStart}&q.field=end_timestamp&q.value=#{searchEnd}"
      eventsParam = "#{serverUrl}/events#{param}"
      deletedParam = "#{serverUrl}/events#{paramDel}"
      existsParam = "#{serverUrl}/events#{paramExist}"

      eventsList = $http.get eventsParam, {
        params:
          all_tenants: 1
      }
        .then (response) ->
          return response.data
      deletedList = $http.get deletedParam, {
        params:
          all_tenants: 1
      }
        .then (response) ->
          return response.data
      existsList = $http.get existsParam, {
        params:
          all_tenants: 1
      }
        .then (response) ->
          return response.data

      $q.all [eventsList, deletedList, existsList]
        .then (values) ->
          if values[0] and values[1] and values[2]
            data = values[2]
            $scope.loading = false
            events = {}
            deleted = {}
            project = []
            ignore = []
            resourceIgnore = []
            for item, index in data
              dictTraits = {}
              for trait in item.traits
                dictTraits[trait.name] = trait.value
              dictTraits['generated'] = item.generated
              dictTraits['show'] = false
              dictTraits['totalHours'] = 0
              if dictTraits['resource_id'] not in resourceIgnore
                resourceIgnore.push dictTraits['resource_id']
              if dictTraits['tenant_id'] not in ignore
                ignore.push dictTraits['tenant_id']
                project.push dictTraits
            # save deleted instance into deleted dict.
            for item, index in values[1]
              dictTrait = {}
              for trait in item.traits
                dictTrait[trait.name] = trait.value
              if dictTrait['resource_id']
                if not deleted[dictTrait['resource_id']]
                  deleted[dictTrait['resource_id']] = []
                deleted[dictTrait['resource_id']].push dictTrait
            # save the exist instance into events dict.
            for item, index in data
              dictTrait = {}
              for trait in item.traits
                dictTrait[trait.name] = trait.value
              dictTrait['generated'] = item.generated
              if dictTrait['tenant_id']
                if not events[dictTrait['tenant_id']]
                  events[dictTrait['tenant_id']] = []
                events[dictTrait['tenant_id']].push dictTrait
            # get the deleted instance which can not get from
            # compute.instance.exists interface into events dict.
            for item, index in values[1]
              dictTrait = {}
              for trait in item.traits
                dictTrait[trait.name] = trait.value
              dictTrait['generated'] = item.generated
              if dictTrait['resource_id'] in resourceIgnore
                continue
              if dictTrait['tenant_id'] and dictTrait['launched_at']
                if not events[dictTrait['tenant_id']]
                  events[dictTrait['tenant_id']] = []
                resourceIgnore.push dictTrait['resource_id']
                events[dictTrait['tenant_id']].push dictTrait
            # Get the instances through the
            # compute.instance.create.end interface.
            # Because instance can not get from the
            # compute.instance.exists interface immediately
            for item, index in values[0]
              dictTrait = {}
              for trait in item.traits
                dictTrait[trait.name] = trait.value
              dictTrait['generated'] = item.generated
              dictTrait['show'] = false
              dictTrait['totalHours'] = 0
              if deleted[dictTrait['resource_id']]
                continue
              if dictTrait['tenant_id'] not in ignore
                ignore.push dictTrait['tenant_id']
                project.push dictTrait
              if dictTrait['resource_id'] not in resourceIgnore \
              and dictTrait['tenant_id']
                resourceIgnore.push dictTrait['resource_id']
                if not events[dictTrait['tenant_id']]
                  events[dictTrait['tenant_id']] = []
                events[dictTrait['tenant_id']].push dictTrait

            getProNameByTenantId(project)
            $scope.projectReprs = []
            if query[2]
              for item in project
                if item['tenant_id'] == query[2]
                  $scope.projectReprs.push item
            else
              $scope.projectReprs = project
            $scope.eventsDict = angular.copy(events)
            getTotalHours()
            # NOTE(liuhaobo): Deal with the data that need
            # export by exportAll function.
            if $scope.projectReprs \
            && $scope.projectReprs.length > 0 \
            && $scope.query.project.project_name == _ 'ALL'
              $scope.statistic.export = false
              for pro in $scope.projectReprs
                getProjectUsage pro.tenant_id
                pro.data = $scope.serverOpts.data
            else
              $scope.statistic.export = true
          else
            $scope.eventsDict = []
            toastr.error _("Failed to a get usage.")

    $scope.getTabStatisticByVolume = (type) ->
      $scope.loading = true
      $scope.query.project = $scope.projectList[0] if type == "tab"
      query = getQuery()
      startAt = query[0]
      endAt = query[1]
      searchDate = getSearchDate(endAt)
      searchStart = searchDate[0]
      searchEnd = searchDate[1]

      param = "?q.field=event_type&q.op=eq&q.value=volume.create.end\
               &q.field=start_timestamp&q.value=#{startAt}&q.field=end_timestamp&q.value=#{endAt}"
      paramDel = "?q.field=event_type&q.op=eq&q.value=volume.delete.end\
               &q.field=start_timestamp&q.value=#{startAt}&q.field=end_timestamp&q.value=#{endAt}"
      paramExist = "?q.field=event_type&q.op=eq&q.value=volume.exists\
               &q.field=start_timestamp&q.value=#{searchStart}&q.field=end_timestamp&q.value=#{searchEnd}"
      eventsParam = "#{serverUrl}/events#{param}"
      deletedParam = "#{serverUrl}/events#{paramDel}"
      existsParam = "#{serverUrl}/events#{paramExist}"

      eventsList = $http.get eventsParam, {
        params:
          all_tenants: 1
      }
        .then (response) ->
          return response.data
      deletedList = $http.get deletedParam, {
        params:
          all_tenants: 1
      }
        .then (response) ->
          return response.data
      existsList = $http.get existsParam, {
        params:
          all_tenants: 1
      }
        .then (response) ->
          return response.data

      $q.all [deletedList, existsList, eventsList]
        .then (values) ->
          if values[0] and values[1] and values[2]
            data = values[1]
            $scope.loading = false
            events = {}
            deleted = {}
            ignore = []
            resourceIgnore = []
            project = []
            for item, index in data
              dictTraits = {}
              for trait in item.traits
                dictTraits[trait.name] = trait.value
              dictTraits['show'] = false
              dictTraits.created_at = stringToDatetime(dictTraits.created_at)
              dictTraits['launched_at'] = dictTraits.created_at
              dictTraits['totalHours'] = 0
              dictTraits['totalSize'] = 0
              if dictTraits['resource_id'] not in resourceIgnore
                resourceIgnore.push dictTraits['resource_id']
              if dictTraits['tenant_id'] not in ignore
                ignore.push dictTraits['tenant_id']
                project.push dictTraits

            for item, index in values[0]
              dictTrait = {}
              for trait in item.traits
                dictTrait[trait.name] = trait.value
              dictTrait.created_at = stringToDatetime(dictTrait.created_at)
              dictTrait['launched_at'] = dictTrait.created_at
              if dictTrait['resource_id']
                if not deleted[dictTrait['resource_id']]
                  deleted[dictTrait['resource_id']] = []
                deleted[dictTrait['resource_id']].push dictTrait

            for item, index in data
              dictTrait = {}
              for trait in item.traits
                dictTrait[trait.name] = trait.value
              dictTrait.created_at = stringToDatetime(dictTrait.created_at)
              dictTrait['launched_at'] = dictTrait.created_at
              if dictTrait['tenant_id']
                if not events[dictTrait['tenant_id']]
                  events[dictTrait['tenant_id']] = []
                events[dictTrait['tenant_id']].push dictTrait

            for item, index in values[0]
              dictTrait = {}
              for trait in item.traits
                dictTrait[trait.name] = trait.value
              dictTrait.created_at = stringToDatetime(dictTrait.created_at)
              dictTrait['launched_at'] = dictTrait.created_at
              dictTrait['deleted_at'] = item.generated
              if dictTrait['resource_id'] in resourceIgnore
                continue
              if dictTrait['tenant_id']
                resourceIgnore.push dictTrait['resource_id']
                if not events[dictTrait['tenant_id']]
                  events[dictTrait['tenant_id']] = []
                events[dictTrait['tenant_id']].push dictTrait

            for item, index in values[2]
              dictTrait = {}
              for trait in item.traits
                dictTrait[trait.name] = trait.value
              dictTrait.created_at = stringToDatetime(dictTrait.created_at)
              dictTrait['launched_at'] = dictTrait.created_at
              dictTrait['totalHours'] = 0
              dictTrait['totalSize'] = 0
              if deleted[dictTrait['resource_id']]
                continue
              if dictTrait['tenant_id'] not in ignore
                ignore.push dictTrait['tenant_id']
                project.push dictTrait
              if dictTrait['resource_id'] not in resourceIgnore \
              and dictTrait['tenant_id']
                resourceIgnore.push dictTrait['tenant_id']
                if not events[dictTrait['tenant_id']]
                  events[dictTrait['tenant_id']] = []
                events[dictTrait['tenant_id']].push dictTrait

            getProNameByTenantId(project)
            $scope.projectReprs = []
            if query[2]
              for item in project
                if item['tenant_id'] == query[2]
                  $scope.projectReprs.push item
            else
              $scope.projectReprs = project
            $scope.eventsDict = angular.copy(events)
            getTotalHours('volumes')
            if $scope.projectReprs \
            && $scope.projectReprs.length > 0 \
            && $scope.query.project.project_name == _ 'ALL'
              $scope.statistic.export = false
              for pro in $scope.projectReprs
                getProjectUsage pro.tenant_id
                pro.data = $scope.serverVolumeOpts.data
            else
              $scope.statistic.export = true
          else
            $scope.eventsDict = []
            toastr.error _("Failed to get volume.")


    getProjectUsage = (projectId) ->
      # Get usage statistic of specific projectId
      query = getQuery()
      startAt = query[0]
      endAt = query[1]
      $scope.serverOpts.data = $scope.eventsDict[projectId]
      $scope.servers = $scope.eventsDict[projectId]
      $scope.serverVolumeOpts.data = $scope.eventsDict[projectId]
      $scope.volumes = $scope.eventsDict[projectId]
      for item, index in $scope.serverOpts.data
        if item.launched_at > startAt
          searchStart = item.launched_at
        else
          searchStart = startAt
        if item.deleted_at and item.deleted_at < endAt
          searchEnd = item.deleted_at
        else
          searchEnd = endAt
        runTime = Date.parse(searchEnd) - Date.parse(searchStart)
        item.run_time = runTime / (3600 * 1000)
      for item, index in $scope.serverVolumeOpts.data
        if item.launched_at > startAt
          searchStart = item.launched_at
        else
          searchStart = startAt
        if item.deleted_at and item.deleted_at < endAt
          searchEnd = item.deleted_at
        else
          searchEnd = endAt
        runTime = Date.parse(searchEnd) - Date.parse(searchStart)
        item.run_time = runTime / (3600 * 1000)

    $scope.$watch 'query', (newVal, odlVal) ->
      if newVal.year == $scope.currentYear
        tmpMonth = []
        for month in $scope.monthNames
          if month.index > $scope.currentMonth
            continue
          else
            tmpMonth.push month
        $scope.monthNames = tmpMonth
      else
        getDateList()
        $scope.query.month = $scope.monthNames[$scope.query.month.index]
    , true

    $scope.columnDefs = [
      {
        field: "resource_name"
        displayName: _("Instance Name")
        cellTemplate: '<div class="ngCellText">{{item[col.field]}}</div>'
      }
      {
        field: "vcpus"
        displayName: _("CPU")
        cellTemplate: '<div class="ngCellText">{{item[col.field]}}</div>'
      }
      {
        field: "memory_mb"
        displayName: _("RAM (GB)")
        cellTemplate: '<div class="ngCellText">{{item[col.field] | unitSwitch}}</div>'
      }
      {
        field: "disk_gb"
        displayName: _("Disk (GB)")
        cellTemplate: '<div class="ngCellText">{{item[col.field]}}</div>'
      }
      {
        field: "run_time"
        displayName: _("Uptime (Hour)")
        cellTemplate: '<div class="ngCellText">{{item[col.field] | fixed}}</div>'
      }
    ]

    $scope.pagingOptions = {
      pageSizes: [15]
      pageSize: 15
      currentPage: 1
      showFooter: false
    }
    $scope.servers = []
    $scope.serverOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: false
      columnDefs: $scope.columnDefs
      pageMax: 5
    }
    $scope.volumeDefs = [
      {
        field: "resource_name"
        displayName: _("Volume Name")
        cellTemplate: '<div class="ngCellText">{{item[col.field]}}</div>'
      }
      {
        field: "size"
        displayName: _("Volume Size")
        cellTemplate: '<div class="ngCellText">{{item[col.field]}}</div>'
      }
      {
        field: "run_time"
        displayName: _("Uptime (Hour)")
        cellTemplate: '<div class="ngCellText">{{item[col.field] | fixed}}</div>'
      }
    ]
    $scope.serverVolumeOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: false
      columnDefs: $scope.volumeDefs
      pageMax: 5
    }

    $scope.tabs[0].initialization = $scope.getTabStatistic
    $scope.tabs[1].initialization = $scope.getTabStatisticByVolume
    $scope.onClickTab = (tab) ->
      tab.initialization("tab")
      $scope.currentTab = tab.template
      $scope.isActiveTab = (tabUrl) ->
        return tabUrl == $scope.currentTab

    $scope.showDetail = (flag, show) ->
      # The show or hide of usage detail
      for pro, index in $scope.projectReprs
        if flag == index
          getProjectUsage pro.tenant_id
          if show
            pro.showOrHide = _ "Show"
            pro.show = false
            pro.active = ''
            continue
          else
            pro.showOrHide = _ "Hide"
            pro.show = true
            pro.active = 'active'
            continue
        else
          pro.showOrHide = _ 'Show'
          pro.show = false
          pro.active = ''

    getProNameByTenantId = (projectRepr) ->
      for item in projectRepr
        for project in $scope.projectList
          if project['tenant_id'] == item['tenant_id']
            item['project_name'] = project['project_name']
            break

    getStatisticByDate = (project, query) ->
      projectReprByDate = []
      for item in project
        if query[0] < item.generated \
        and query[1].slice(1, 10) >= item.generated.slice(1, 10)
          projectReprByDate.push item
      return projectReprByDate

    getTotalHours = (type) ->
      query = getQuery()
      startAt = query[0]
      endAt = query[1]
      for pro in $scope.projectReprs
        instances = $scope.eventsDict[pro.tenant_id]
        for item, index in instances
          if item.launched_at > startAt
            startTime = item.launched_at
          else
            startTime = startAt
          if item.deleted_at < endAt
            endTime = item.deleted_at
          else
            endTime = endAt
          dateed = Date.parse(endTime) - Date.parse(startTime)
          item.run_time = dateed / (3600 * 1000)
          pro.totalHours += item.run_time if item.run_time
          pro.totalSize += parseInt(item.size) if item.size
        pro.totalHours = pro.totalSize * pro.totalHours if type == 'volumes'

    $scope.loading = false

    # NOTE(liuhaobo): getStatisticNew is used to get
    # all projects info include of deleted projects
    $scope.getStatisticNew = () ->
      $scope.statistic = {query: true}
      # Get usage statistic of all projects
      $scope.loading = true
      $scope.projects = []
      query = getQuery()
      startAt = query[0]
      endAt = query[1]
      searchDate = getSearchDate(endAt)
      searchStart = searchDate[0]
      searchEnd = searchDate[1]
      param = "?q.field=event_type&q.op=eq&q.value=compute.instance.create.end\
               &q.field=start_timestamp&q.value=#{startAt}&q.field=end_timestamp&q.value=#{endAt}"
      paramExist = "?q.field=event_type&q.op=eq&q.value=compute.instance.exists\
               &q.field=start_timestamp&q.value=#{searchStart}&q.field=end_timestamp&q.value=#{searchEnd}"
      paramDel = "?q.field=event_type&q.op=eq&q.value=compute.instance.delete.end\
                  &q.field=start_timestamp&q.value=#{startAt}&q.field=end_timestamp&q.value=#{endAt}"
      projectParam = "#{serverUrl}/projectsV3"
      eventsParam = "#{serverUrl}/events#{param}"
      deletedParam = "#{serverUrl}/events#{paramDel}"
      existParam = "#{serverUrl}/events#{paramExist}"

      eventsList = $http.get eventsParam, {
        params:
          all_tenants: 1
      }
        .then (response) ->
          return response.data

      projectList = $http.get projectParam
        .then (response) ->
          return response.data
      existList = $http.get existParam, {
        params:
          all_tenants: 1
      }
        .then (response) ->
          return response.data
      deletedList = $http.get deletedParam, {
        params:
          all_tenants: 1
      }
        .then (response) ->
          return response.data

      $q.all ([projectList, existList, deletedList, eventsList])
        .then (values) ->
          if values[0] and values[1] and values[2] and values[3]
            data = values[1]
            $scope.loading = false
            events = {}
            deleted = {}
            projects = []
            ignore = []
            for event in data
              dictTraits = {}
              for trait in event.traits
                 dictTraits[trait.name] = trait.value
              dictTraits['generated'] = event.generated
              dictTraits['show'] = false
              dictTraits['totalHours'] = 0
              if dictTraits['tenant_id'] not in ignore
                ignore.push dictTraits['tenant_id']
                projects.push dictTraits

            for event in values[2]
              dictTraits = {}
              for trait in event.traits
                dictTraits[trait.name] = trait.value
              dictTraits['show'] = false
              dictTraits['totalHours'] = 0
              if dictTraits['tenant_id'] not in ignore
                ignore.push dictTraits['tenant_id']
                projects.push dictTraits

            for event in values[3]
              dictTraits = {}
              for trait in event.traits
                dictTraits[trait.name] = trait.value
              dictTraits['show'] = false
              dictTraits['totalHours'] = 0
              if dictTraits['tenant_id'] not in ignore
                ignore.push dictTraits['tenant_id']
                projects.push dictTraits

            # get the project name
            for item in projects
              for project in values[0].data
                if item['tenant_id'] == project['id']
                  item['project_name'] = project['name']
              if not item['project_name']
                desc = _ "Deleted"
                projectName = [item['tenant_id'].slice(0, 9), "(", desc, ")"]
                item['project_name'] = projectName.join("")

            $scope.projectRepr = projects

            $scope.statistic.query = false
            # NOTE(liuhaobo): Make search when come in statistic
            # page.
            $scope.getTabStatistic()
          else
            toastr.error _("Failed to a get usage.")

    $scope.getStatisticNew()
