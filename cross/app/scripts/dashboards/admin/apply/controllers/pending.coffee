'use strict'

angular.module('Cross.admin.apply')
  .controller 'admin.apply.pendingCtr', ($scope, $http, $window, $q,
  $state) ->
    $scope.AllSelectedItems = false
    $scope.NoSelectedItems = true

    $scope.showFooter = true
    $scope.unFristPage = false
    $scope.unLastPage = false

    $scope.totalServerItems = 0
    $scope.pagingOptions = {
      pageSizes: [15, 25, 50]
      pageSize: 15
      currentPage: 1
    }

    $scope.deleteAction = _ "Delete"
    $scope.approveAction = _ "Approve"
    $scope.rejectAction = _ "Reject"
    $scope.refesh = _("Refresh")
    $scope.deleteEnabledClass = 'btn-disable'
    $scope.retryEnabledClass = 'btn-disable'
    $scope.retrigger = _ "Retry"
    $scope.retry = _ "Retry resource create for"

    $scope.isApproveAlarm = false

    $scope.applys = []

    $scope.columnDefs = [
      {
        field: 'request_type_display_name'
        displayName: _("Apply Type")
        cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="admin.apply.applyId.overview({applyId: item.id})" ng-bind="item[col.field]"></></div>'
      }
      {
        field: 'project_name'
        displayName: _("Project")
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]"></div>'
      }
      {
        field: 'user_name'
        displayName: _("User")
        cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]"></div>'
      }
      {
        field: 'created_at'
        displayName: _("Created At")
        cellTemplate: '<div class="ngCellText">{{item.created_at | dateLocalize | date: "yyyy-MM-dd HH:mm"}}</div>'
      }
      {
        field: 'status'
        displayName: _("Status")
        cellTemplate: '<div class="ngCellText">{{item.status}}</div>'
      }
    ]

    $scope.applysOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      pageMax: 5
    }

    $scope.statusMap = {
      1: _ "Pending"
      2: _ "Waiting Resource Creating"
      3: _ "Rejected"
      4: _ "Revoked"
      5: _ "Completed"
      6: _ "Expired"
      7: _ "Resource Creating"
      8: _ "Failed at resource creating"
    }

    $scope.setPagingData = (pagedData, total) ->
      $scope.applys = pagedData
      $scope.totalServerItems = total
      $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
      $scope.applysOpts.data = $scope.applys
      $scope.applysOpts.pageCounts = $scope.pageCounts

      for apply in pagedData
        apply.status = $scope.statusMap[apply.state]

      if !$scope.$$phase
        $scope.$apply()

    $scope.selectedItems = []

    $scope.selectChange = () ->
      if $scope.selectedItems.length >= 1
        $scope.createInstances = []
        $scope.otherApply = []
        $scope.deleteEnabledClass = 'btn-enable'
        for item in $scope.selectedItems
          #(NOTE): When state of apply is "Failed at resource createing"
          # Allow admin to retrigger resource create.
          if item.state == 8 and $scope.selectedItems.length == 1
            $scope.retryEnabledClass = 'btn-enable'
          else
            $scope.retryEnabledClass = 'btn-disable'
          if item.request_type_name == 'create instance'
            $scope.createInstances.push item
          else
            $scope.otherApply.push item

        if $scope.createInstances.length > 0
          $scope.isApproveAlarm = true
        else
          $scope.isApproveAlarm = false
      else
        $scope.deleteEnabledClass = 'btn-disable'
        $scope.retryEnabledClass = 'btn-disable'
        $scope.isApproveAlarm = false

    $scope.getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        serverURL = $window.$CROSS.settings.serverURL
        fixArgs = '/workflow-requests?all_project=True'
        pageArg = "&current_page=#{currentPage}&page_size=#{pageSize}"
        if $scope.currentTab == 'pending.tpl.html'
          workflowParam = "&state=1"
        else if $scope.currentTab == 'error.tpl.html'
          workflowParam = '&state=2,3,7,8'
        else if $scope.currentTab == 'reviewed.tpl.html'
          workflowParam = '&state=4,5,6'

        workflowURL = "#{serverURL}#{fixArgs}#{pageArg}#{workflowParam}"
        $http.get(workflowURL)
          .success (data, status, headers) ->
            for wf in data.list
              wfContent = JSON.parse(wf.content)
              wf.display_name = wfContent.request_name
              wf.id = String(wf.id)
            $scope.setPagingData(data.list,
                                 data.total)
          .error (data, status, headers) ->
            $scope.setPagingData([], 0)
            toastr.error(_("Failed to get applys!"))
        (callback && typeof(callback) == "function") && callback()
      , 300)

    $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    watchCallback = (newVal, oldVal) ->
      $scope.applysOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage

    $scope.$watch('pagingOptions', watchCallback, true)

    applyCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for apply in newVal
          if $scope.selectedApplyId
            if apply.id == $scope.selectedApplyId
              apply.isSelected = true
              $scope.selectedApplyId = undefined
          if apply.isSelected == true
            selectedItems.push apply

        $scope.selectedItems = selectedItems

    $scope.$watch('applys', applyCallback, true)
    $scope.$watch('selectedItems', $scope.selectChange, true)

    $scope.deleteApply = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        applyId = item.id
        serverURL = $window.$CROSS.settings.serverURL
        param = "#{serverURL}/workflow-requests/#{applyId}"
        $http.delete param
          .success (data, status, headers) ->
            toastr.success(_("Success delete apply!"))
          .error (data, status, headers) ->
            toastr.error(_("Failed delete apply!"))
        $state.go "admin.apply", {}, {reload: true}

    $scope.retryCreate = () ->
      selectedApply = $scope.selectedItems[0]
      applyId = selectedApply.id
      serverURL = $window.$CROSS.settings.serverURL
      param = "#{serverURL}/workflow-requests/#{applyId}"
      selectedApply.state = 2
      $http.put param, selectedApply
        .success (data, status) ->
          toastr.success _ "Success to retry resource create."
          $scope.refresResource()
        .error (err) ->
          toastr.error _ "Failed to retry resource create."

    $scope.$on 'selected', (event, detail) ->
      if $scope.applys.length > 0
        for apply, index in $scope.applys
          if ('' + apply.id + '') == detail
            apply.isSelected = true
          else
            apply.isSelected = false
      else
        $scope.selectedApplyId = detail

    $scope.refresResource = (resource) ->
      $scope.applysOpts.data = null
      $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                               $scope.pagingOptions.currentPage)

    $scope.rejectApply = () ->
      params = {
        applys: $scope.selectedItems
      }
      paramsStr = JSON.stringify params
      $state.go 'admin.apply.rejectdata', {data: paramsStr}

    $scope.approveApply = () ->
      # Separate apply with different type
      if $scope.isApproveAlarm
        params = {
            instance: $scope.createInstances
            other: $scope.otherApply
        }

        params = JSON.stringify params
        $state.go 'admin.apply.approvedata', {
          data: params
        }
      else
        serverURL = $window.$CROSS.settings.serverURL
        applyParam = "#{serverURL}/workflow-requests/"
        angular.forEach $scope.otherApply, (item, index) ->
          content = JSON.parse(item.content)
          content = {
            content: content
            state: 2
            id: item.id
          }
          $http.put "#{applyParam}#{item.id}", content
            .success (data, status, headers) ->
              toastr.success(_("Success approve apply: ") + item.id)
            .error (data, status, headers) ->
              toastr.error(_("Failed approve apply: ") + item.id)
        $state.go 'admin.apply', {}, {reload: true}

  .controller 'admin.apply.approveCtr', ($scope, $http, $window, $q,
  $state, $stateParams) ->
    data = JSON.parse $stateParams.data
    $scope.createInstances = data.instance
    if !$scope.createInstances
      $state.go 'admin.apply'
    $scope.otherApply = data.other
    (new SelectZoneModal()).initial($scope, {
      $state: $state,
      $http: $http,
      $window: $window
      instanceApplys: $scope.createInstances
      otherApplys: $scope.otherApply
    })
    $scope.note.modal.save = _("Approve")

    # Get available zone for instance create
    $cross.listClusters($http, $window, $q, (data) ->
      $scope.clusters = []
      for cluster in data
        if cluster.compute_nodes.length > 0
          item = {text: cluster.name, value: cluster.name}
          $scope.clusters.push item
      $scope.modal.fields[0].default = $scope.clusters
      if $scope.clusters.length > 0
        $scope.form['cluster'] = $scope.clusters[0].value
    )

  .controller 'admin.apply.rejectCtr', ($scope, $http, $window, $q,
  $state, $stateParams) ->
    $scope.applys = JSON.parse $stateParams.data
    (new RejectModal()).initial($scope, {
      $state: $state,
      $http: $http,
      $window: $window
      applys: $scope.applys
    })
    $scope.note.modal.save = _("Reject")

class RejectModal extends $cross.Modal
  title: _ 'Reject Apply'
  slug: 'reject_apply'

  fields: ->
    [
      {
        slug: 'comment'
        label: _ 'Reason of reject'
        tag: 'textarea'
        restrictions:
          required: false
      }
    ]

  handle: ($scope, options) ->
    serverURL = options.$window.$CROSS.settings.serverURL
    applyParam = "#{serverURL}/workflow-requests/"
    comment = $scope.form.comment
    for apply in options.applys
      content = {
        state: 1
        id: apply.id
        comments: comment
      }
      options.$http.put "#{applyParam}#{apply.id}", content
        .success (data, status, headers) ->
          toastr.success(_("Success reject apply: ") + apply.id)
        .error (data, status, headers) ->
          toastr.error(_("Failed reject apply: ") + apply.id)
    options.$state.go "admin.apply", {}, {reload: true}

class SelectZoneModal extends $cross.Modal
  title: _ 'Choose Cluster'
  slug: 'choose_cluster'

  fields: ->
    [
      {
        slug: 'cluster'
        label: _ 'Available Cluster'
        tag: 'select'
        default: [{text: '111', value: true}]
        restrictions:
          required: true
      }
    ]

  handle: ($scope, options) ->
    serverURL = options.$window.$CROSS.settings.serverURL
    applyParam = "#{serverURL}/workflow-requests/"
    clusterName = $scope.form.cluster
    for apply in options.instanceApplys
      content = JSON.parse(apply.content)
      content.availability_zone = clusterName
      content = {
        content: content
        state: 2
        id: apply.id
      }
      options.$http.put "#{applyParam}#{apply.id}", content
        .success (data, status, headers) ->
          toastr.success(_("Success approve apply: ") + apply.id)
        .error (data, status, headers) ->
          toastr.error(_("Failed approve apply: ") + apply.id)
    for applyRef in options.otherApplys
      content = JSON.parse(applyRef.content)
      content = {
        content: content
        state: 2
        id: applyRef.id
      }
      options.$http.put "#{applyParam}#{applyRef.id}", content
        .success (data, status, headers) ->
          toastr.success(_("Success approve apply: ") + applyRef.id)
        .error (data, status, headers) ->
          toastr.error(_("Failed approve apply: ") + applyRef.id)
    options.$state.go "admin.apply", {}, {reload: true}
