'use strict'

angular.module('Cross.project.metering')
  .controller 'project.metering.MeteringCtr', ($scope, $window, $http, $q, $tabs) ->
    serverUrl = $CROSS.settings.serverURL
    if $CROSS.person
        projectId = $CROSS.person.project.id
        $scope.projectId = projectId
    $scope.note =
      title: _("Volume Type")
      buttonGroup:
        create: _("Create")
        delete: _("Delete")
        modify: _("Modify")
        refresh: _("Refresh")
      query: _("Query")
      project: _("Project Name")
      export: _("Export")
      cpuUsage: _("CPU Hours")
      memUsage: _("RAM Hours(GB*Hour)")
      diskUsage: _("Disk Hours(GB*Hour)")
      totalUsage: _("Resources Uptime(Hour)")
      totalPrice: _("Consume Price")
      detailUsage: _("Detail usage of instances")
      usagenull: _("Temporarily no statistic data!")
      all: _("ALL")
      export_all: _("Export All")
      space: ("      ")
    $scope.tabs = [{
      title: _('user')
      template: 'pending.tpl.html'
      enable: true
      slug: 'pending'
    }
    ]
    $scope.currentTab = 'pending.tpl.html'
    $tabs $scope, 'project.metering'
    $scope.onClickTab = (tab) ->
      $scope.currentTab = tab.template

    $scope.batchActionEnableClass = 'btn-disable'

    $scope.pagingOptions = {
      pageSize: 1000
      currentPage: 1
    }
    $scope.filterOptions =
      filterText: '',
      useExternalFilter: true

    $scope.meteringsOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.userColumnDefs
      pageMax: 5
    }

    listDetailedSettings = (callback) ->
      resourcePrice = []
      resourcePriceObj = {}
      $http.get("#{serverUrl}/prices")
        .success (itemList)->
          for i in itemList
            resourcePrice.push({name: i.name,value:i.price})
            resourcePriceObj[i.name] = i.price
          $scope.resourcePriceObj = resourcePriceObj
          #add by davidzgao
          $scope.getStatisticNew()
          callback(resourcePrice, resourcePrice.length)
        .error (error)->
          toastr.error _("Failed to get priceService.")

    getPagedDataAsync = (pageSize, currentPage, callback) ->
      dataQueryOpts = {}
      listDetailedSettings (resourcePrice,len_resourcePrice) ->
        $scope.resourcePrice = resourcePrice
        $scope.pageCount = 1
        if !$scope.$$phase
          $scope.$apply()
        if callback
          callback()

    getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    watchCallback = (newVal, oldVal) ->
      tbody = angular.element('tbody.cross-data-table-body')
      tbody.hide()
      loadCallback = () ->
        tbody.show()
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage,
                                 loadCallback

    $scope.$watch('pagingOptions', watchCallback, true)

    $scope.refresResource = (resource) ->
      tbody = angular.element('tbody.cross-data-table-body')
      tbody.hide()
      loadCallback = () ->
        tbody.show()
        toastr.options.closeButton = true
      getPagedDataAsync($scope.pagingOptions.pageSize,
                        $scope.pagingOptions.currentPage,
                        loadCallback)

    # TODO(liuhaobo): Add the function of exportAll and exportData
    $scope.exportAll = () ->
      $scope.statistic = {query: true}
      query = getQuery()
      startAt = query[0]
      endAt = query[1]
      params = "?start=#{startAt}&end=#{endAt}"
      if $scope.projectId
        selectProId = $scope.projectId
      tableStr = "<table class='usage-table'>"

      for project, index in $scope.projectReprs
        if selectProId && project.tenant_id != selectProId
          continue
        str1 = "<tr><td>#{$scope.note.project}:#{project.project_name}  </td><td> #{$scope.note.totalUsage}: #{project.totalHours}  </td> \
                    <td> #{$scope.note.totalPrice}:#{project.totalPrice} </td></tr>"
        str1 += "<tr>"
        for col in $scope.columnDownloadDefs
          str1 += "<td>#{col.displayName}</td>"
        str1 += "</tr>"
        instances = $scope.eventsDict[project.tenant_id]
        for item, index in instances
          str1 += "<tr>"
          for col in $scope.columnDownloadDefs
            str1 += "<td>#{item[col.field]}</td>"
          str1 += "</tr>"
        tableStr += str1 + "<tr></tr>"
      tableStr += "</table>"
      exp = new Blob([tableStr],
      {
        type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=utf-8"
      })
      saveAs(exp, "Report_all.xls")
      $scope.statistic.query = false

    $scope.exportData = (ind) ->
      # Function for export datatable as .xls file
      for project, index in $scope.projectReprs
        if index == ind
          argId = "project_#{project.tenant_id}_statistic"
          exp = new Blob([document.getElementById(argId).innerHTML],
          {
            type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;charset=utf-8"
          })
          saveAs(exp, "Report_#{project.tenant_id}.xls")
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
      lastDay = new Date(year, month + 1, 0)
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

    # NOTE(liuhaobo): get the statistic info when click on tab
    $scope.getTabStatistic = (type) ->
      $scope.loading = true
      $scope.query.project = $scope.projectList[0] if type == "tab"
      query = getQuery()
      startAt = query[0]
      endAt = query[1]
      param = "?q.field=event_type&q.op=eq&q.value=compute.instance.create.end\
               &q.field=start_time&q.value=#{startAt}&q.field=end_time&q.value=#{endAt}"
      paramDel = "?q.field=event_type&q.op=eq&q.value=compute.instance.delete.end\
                  &q.field=start_time&q.value=#{startAt}&q.field=end_time&q.value=#{endAt}"
      eventsParam = "#{serverUrl}/events#{param}"
      deletedParam = "#{serverUrl}/events#{paramDel}"

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

      #add by davidzgao
      paramVol = "?q.field=event_type&q.op=eq&q.value=volume.create.end\
               &q.field=start_time&q.value=#{startAt}&q.field=end_time&q.value=#{endAt}"
      paramDelVol = "?q.field=event_type&q.op=eq&q.value=volume.delete.end\
               &q.field=start_time&q.value=#{startAt}&q.field=end_time&q.value=#{endAt}"
      eventsParamVol = "#{serverUrl}/events#{paramVol}"
      deletedParamVol = "#{serverUrl}/events#{paramDelVol}"
      eventsListVol = $http.get eventsParamVol, {
        params:
          all_tenants: 1
      }
        .then (response) ->
          return response.data
      deletedListVol = $http.get deletedParamVol, {
        params:
          all_tenants: 1
      }
        .then (response) ->
          return response.data
      #end add

      $q.all [eventsList, deletedList, eventsListVol, deletedListVol]
        .then (values) ->
          if values[0] and values[1]
            data = values[0]
            dataVol = values[2]
            delVol = values[3]
            $scope.loading = false
            events = {}
            deleted = {}
            project = []
            ingore = []
            for event, index in data
              dictTraits = {}
              for trait in event.traits
                dictTraits[trait.name] = trait.value
              dictTraits['generated'] = event.generated
              dictTraits['show'] = false
              dictTraits['totalHours'] = 0
              #add by davidzgao
              dictTraits['totalPrice'] = 0
              if dictTraits['tenant_id'] not in ingore
                ingore.push dictTraits['tenant_id']
                project.push dictTraits

            for event, index in values[1]
              dictTrait = {}
              for trait in event.traits
                dictTrait[trait.name] = trait.value
              if dictTrait['resource_id']
                if not deleted[dictTrait['resource_id']]
                  deleted[dictTrait['resource_id']] = []
                deleted[dictTrait['resource_id']].push dictTrait

            for event, index in data
              dictTrait = {}
              for trait in event.traits
                dictTrait[trait.name] = trait.value
              dictTrait['generated'] = event.generated
              if deleted[dictTrait['resource_id']]
                dictTrait['deleted_at'] = deleted[dictTrait['resource_id']][0].deleted_at
              if dictTrait['tenant_id']
                if not events[dictTrait['tenant_id']]
                  events[dictTrait['tenant_id']] = []
                events[dictTrait['tenant_id']].push dictTrait

            #add by davidzgao
            for event, index in dataVol
              dictTraits = {}
              for trait in event.traits
                dictTraits[trait.name] = trait.value
              dictTraits['show'] = false
              dictTraits['generated'] = event.generated
              dictTraits['totalHours'] = 0
              dictTraits['totalPrice'] = 0
              if dictTraits['tenant_id'] not in ingore and dictTraits['generated'] != undefined
                ingore.push dictTraits['tenant_id']
                project.push dictTraits

            for event, index in delVol
              dictTrait = {}
              for trait in event.traits
                dictTrait[trait.name] = trait.value
              dictTrait['generated'] = event.generated
              if dictTrait['resource_id']
                if not deleted[dictTrait['resource_id']]
                  deleted[dictTrait['resource_id']] = []
                deleted[dictTrait['resource_id']].push dictTrait

            for event, index in dataVol
              dictTrait = {}
              for trait in event.traits
                dictTrait[trait.name] = trait.value
              dictTrait['generated'] = event.generated
              if deleted[dictTrait['resource_id']]
                dictTrait['deleted_at'] = deleted[dictTrait['resource_id']][0].generated
              if dictTrait['tenant_id']
                if not events[dictTrait['tenant_id']]
                  events[dictTrait['tenant_id']] = []
                events[dictTrait['tenant_id']].push dictTrait

            getProNameByTenantId(project)
            $scope.projectReprs = []
            if $scope.projectId
              for item in project
                if item['tenant_id'] == $scope.projectId
                  $scope.projectReprs.push item
            else
              $scope.projectReprs = project
            $scope.eventsDict = events
            getTotalHours()
          else
            $scope.eventsDict = []
            toastr.error _("Failed to a get usage.")

    getProjectUsage = (projectId) ->
      # Get usage statistic of specific projectId
      query = getQuery()
      startAt = query[0]
      endAt = query[1]
      $scope.serverOpts.data = $scope.eventsDict[projectId]
      for item, index in $scope.serverOpts.data
        if item['deleted_at']
          dateDay = Date.parse(item.deleted_at)
        else
          dateDay = Date.parse(endAt)
        runTime = dateDay - Date.parse(item.generated)
        item.run_time = runTime / (3600 * 1000)
      servers = []
      for item in $scope.serverOpts.data
        servers.push item
      $scope.servers = servers

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
        $scope.query.month = $scope.monthNames[$scope.currentMonth]
    , true

    $scope.columnDefs = [
      {
        field: "resource_name"
        displayName: _("ResourceName")
        cellTemplate: '<div class="ngCellText"><a ui-sref="project.metering.instanceDetail({ \
                       service: \'{{item.service}}\',
                       cpus:\'{{item.vcpus}}\',
                       name:\'{{item[col.field]}}\',
                       run_time:\'{{item.run_time}}\',
                       mem:\'{{item.memory_mb | unitSwitch}}\',
                       disk:\'{{item.disk_gb}}\',
                       size:\'{{item.size}}\'
                       })">{{item[col.field]}}</a></div>'
      }
      {
        field: "run_time"
        displayName: _("Uptime (Hour)")
        cellTemplate: '<div class="ngCellText">{{item[col.field] | fixed}}</div>'
      }
      {
        field: "run_price"
        displayName: _("Price")
        cellTemplate: '<div class="ngCellText">{{item[col.field] | fixed}}</div>'
      }
    ]

    $scope.columnDownloadDefs = [
      {
        field: "resource_name"
        displayName: _("ResourceName")
      }
      {
        field: "vcpus"
        displayName: _("CPU")
      }
      {
        field: "memory_mb"
        displayName: _("RAM")
      }
      {
        field: "disk_gb"
        displayName: _("Disk (GB)")
      }
      {
        field: "run_time"
        displayName: _("Uptime (Hour)")
      }
      {
        field: "run_price"
        displayName: _("Price")
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

    $scope.serverVolumeOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: false
      columnDefs: $scope.columnDefs
      pageMax: 5
    }

    $scope.tabs[0].initialization = $scope.getTabStatistic


    $scope.showDetail = (flag, show) ->
      # The show or hide of usage detail
      for pro, index in $scope.projectReprs
        if flag == index
          getProjectUsage pro.tenant_id
          if show
            pro.showOrHide = _ "Show"
            pro.show = false
            pro.active = ''
          else
            pro.showOrHide = _ "Hide"
            pro.show = true
            pro.active = 'active'
        else
          pro.showOrHide = _ 'Show'
          pro.show = false
          pro.active = ''

    getProNameByTenantId = (projectRepr) ->
      for project in $scope.projectRepr
        for item in projectRepr
          if project['tenant_id'] == item['tenant_id']
            item['project_name'] = project['project_name']

    getStatisticByDate = (project, query) ->
      projectReprByDate = []
      for item in project
        if query[0] < item.generated and query[1].slice(1, 10) >= item.generated.slice(1, 10)
          projectReprByDate.push item
      return projectReprByDate

    getTotalHours = () ->
      query = getQuery()
      startAt = query[0]
      endAt = query[1]
      RPobj = $scope.resourcePriceObj
      for pro in $scope.projectReprs
        instances = $scope.eventsDict[pro.tenant_id]
        for item, index in instances
          if item['deleted_at']
            dateDay = Date.parse(item.deleted_at)
          else
            dateDay = Date.parse(endAt)
          dateed = dateDay - Date.parse(item.generated)
          item.run_time = dateed / (3600 * 1000)
          pro.totalHours += item.run_time if item.run_time
          #add by davidzgao
          item.run_price = getInstancePrice(item, RPobj)
          item.resource_name = changeInstacenName(item)
          addVolumeInstanceDiskField(item)
          pro.totalPrice += item.run_price if item.run_price

    addVolumeInstanceDiskField = (instance) ->
      if instance.service.match("^volume")
        instance.disk_gb = instance.size

    getInstancePrice = (instance, RPobj) ->
      run_price = 0
      if instance.service.match("^compute")
        run_price = (parseInt(instance.vcpus) * RPobj.cpu + parseInt(instance.memory_mb) / 1024  * RPobj.ram+ parseInt(instance.disk_gb) * RPobj.volume ) * instance.run_time
      else if instance.service.match("^volume")
        run_price = (parseInt(instance.size) * RPobj.volume ) * instance.run_time
      return run_price
    changeInstacenName = (instance) ->
      resource_name = ""
      if instance.service.match("^compute")
        resource_name = instance.resource_name + _("(service_compute)")
      else if instance.service.match("^volume")
        resource_name = instance.resource_name + _("(service_volume)")
      return resource_name

    $scope.loading = false

    $scope.getStatisticNew = () ->
      $scope.statistic = {query: true}
      # Get usage statistic of all projects
      $scope.loading = true
      $scope.projects = []
      query = getQuery()
      startAt = query[0]
      endAt = query[1]
      param = "?q.field=event_type&q.op=eq&q.value=compute.instance.create.end\
               &q.field=start_time&q.value=#{startAt}&q.field=end_time&q.value=#{endAt}"
      paramDel = "?q.field=event_type&q.op=eq&q.value=compute.instance.delete.end\
               &q.field=start_time&q.value=#{startAt}&q.field=end_time&q.value=#{endAt}"
      projectParam = "#{serverUrl}/projectsV3"
      eventsParam = "#{serverUrl}/events#{param}"
      deletedParam = "#{serverUrl}/events#{paramDel}"
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
      projectList = $http.get projectParam
        .then (response) ->
          return response.data

      #add by davidzgao
      paramVol = "?q.field=event_type&q.op=eq&q.value=volume.create.end\
               &q.field=start_time&q.value=#{startAt}&q.field=end_time&q.value=#{endAt}"
      paramDelVol = "?q.field=event_type&q.op=eq&q.value=volume.delete.end\
               &q.field=start_time&q.value=#{startAt}&q.field=end_time&q.value=#{endAt}"
      eventsParamVol = "#{serverUrl}/events#{paramVol}"
      deletedParamVol = "#{serverUrl}/events#{paramDelVol}"
      eventsListVol = $http.get eventsParamVol, {
        params:
          all_tenants: 1
      }
        .then (response) ->
          return response.data
      deletedListVol = $http.get deletedParamVol, {
        params:
          all_tenants: 1
      }
        .then (response) ->
          return response.data
      #end add

      $q.all ([eventsList, projectList, deletedList, eventsListVol, deletedListVol])
        .then (values) ->
          if values[0] and values[1]
            data = values[0]
            dataVol = values[3]
            delVol = values[4]
            $scope.loading = false
            events = {}
            deleted = {}
            projects = []
            ingore = []
            for event in data
              dictTraits = {}
              for trait in event.traits
                 dictTraits[trait.name] = trait.value
              dictTraits['generated'] = event.generated
              dictTraits['show'] = false
              dictTraits['totalHours'] = 0
              #add by davidzgao
              dictTraits['totalPrice'] = 0
              if dictTraits['tenant_id'] not in ingore
                  ingore.push dictTraits['tenant_id']
                  projects.push dictTraits
            for item in projects
              for project in values[1].data
                if item['tenant_id'] == project['id']
                  item['project_name'] = project['name']
              if not item['project_name']
                desc = _ "Deleted"
                projectName = [item['tenant_id'].slice(0, 9), "(", desc, ")"]
                item['project_name'] = projectName.join("")

            $scope.projectRepr = projects

            for event, index in values[2]
              dictTrait = {}
              for trait in event.traits
                dictTrait[trait.name] = trait.value
              if dictTrait['resource_id']
                if not deleted[dictTrait['resource_id']]
                  deleted[dictTrait['resource_id']] = []
                deleted[dictTrait['resource_id']].push dictTrait

            for event, index in data
              dictTrait = {}
              for trait in event.traits
                dictTrait[trait.name] = trait.value
              dictTrait['generated'] = event.generated
              if deleted[dictTrait['resource_id']]
                dictTrait['deleted_at'] = deleted[dictTrait['resource_id']][0].deleted_at
              if dictTrait['tenant_id']
                if not events[dictTrait['tenant_id']]
                  events[dictTrait['tenant_id']] = []
                events[dictTrait['tenant_id']].push dictTrait

            #add by davidzgao
            for event, index in dataVol
              dictTraits = {}
              for trait in event.traits
                dictTraits[trait.name] = trait.value
              dictTraits['show'] = false
              dictTraits['generated'] = event.generated
              dictTraits['totalHours'] = 0
              dictTraits['totalPrice'] = 0
              if dictTraits['tenant_id'] not in ingore and dictTraits['generated'] != undefined
                ingore.push dictTraits['tenant_id']
                projects.push dictTraits

            for event, index in delVol
              dictTrait = {}
              for trait in event.traits
                dictTrait[trait.name] = trait.value
              dictTrait['generated'] = event.generated
              if dictTrait['resource_id']
                if not deleted[dictTrait['resource_id']]
                  deleted[dictTrait['resource_id']] = []
                deleted[dictTrait['resource_id']].push dictTrait

            for event, index in dataVol
              dictTrait = {}
              for trait in event.traits
                dictTrait[trait.name] = trait.value
              dictTrait['generated'] = event.generated
              if deleted[dictTrait['resource_id']]
                dictTrait['deleted_at'] = deleted[dictTrait['resource_id']][0].generated
              if dictTrait['tenant_id']
                if not events[dictTrait['tenant_id']]
                  events[dictTrait['tenant_id']] = []
                events[dictTrait['tenant_id']].push dictTrait
            #end add

            if (data && data.length != 0) || (dataVol && dataVol.length != 0)
              getProNameByTenantId(projects)
              $scope.projectReprs = []
              if $scope.projectId
                for item in projects
                  if item['project_id'] == $scope.projectId
                    $scope.projectReprs.push item
              $scope.eventsDict = events
              $scope.deletedDict = deleted
              getTotalHours()
            else
              $scope.eventsDict = []
            $scope.statistic.query = false
          else
            toastr.error _("Failed to a get usage.")
