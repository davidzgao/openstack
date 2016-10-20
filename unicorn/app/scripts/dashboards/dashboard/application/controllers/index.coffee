'use strict'

###*
 # @ngdoc function
 # @name Unicorn.dashboard.instance:ApplicationCtr
 # @description
 # # ApplicationCtr
 # Controller of the Unicorn
###
angular.module("Unicorn.dashboard.application")
  .controller "dashboard.application.ApplicationCtr", ($scope, $tabs) ->
    $scope.tabs = [{
      title: _('Pending')
      template: 'pending.apply.html'
      enable: true
      slug: 'pending'
    }, {
      title: _("Reviewed")
      template: 'reviewed.apply.html'
      enable: true
      slug: 'reviewed'
    }]

    $scope.currentTab = 'pending.apply.html'
    $tabs $scope, 'dashboard.application'
  .controller "dashboard.application.pendingCtr", ($scope, $http,
  $q, $window, $state, $dataLoader) ->
    pendingTable = new PendingApply()
    pendingTable.init($scope, {
      $state: $state
      $http: $http
      $window: $window
      $q: $q
      $dataLoader: $dataLoader
    })
    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      buttons: [
        {
          type: 'single'
          tag: 'button'
          name: 'del'
          verbose: _("Delete")
          action: $scope.itemDelete
          enable: false
          confirm: _ 'Delete Apply'
          restrict: {
            batch: true
            state: 1
          }
        }
      ]
    }
  .controller "dashboard.application.errorCtr", ($scope, $http,
  $q, $window, $state, $dataLoader) ->
    errorTable = new ErrorApply()
    errorTable.init($scope, {
      $state: $state
      $http: $http
      $window: $window
      $q: $q
      $dataLoader: $dataLoader
    })
    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      buttons: [
        {
          type: 'single'
          tag: 'button'
          name: 'del'
          verbose: _("Delete")
          action: $scope.itemDelete
          enable: false
          confirm: _ 'Delete'
          restrict: {
            batch: true
          }
        }
      ]
    }
  .controller "dashboard.application.reviewedCtr", ($scope, $http,
  $q, $window, $state, $dataLoader) ->
    errorTable = new ReviewedApply()
    errorTable.init($scope, {
      $state: $state
      $http: $http
      $window: $window
      $q: $q
      $dataLoader: $dataLoader
    })
    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      buttons: [
        {
          type: 'single'
          tag: 'button'
          name: 'edit'
          verbose: _("Edit")
          action: $scope.editApply
          enable: false
          restrict: {
            batch: false
            state: 3
          }
          needConfirm: true
        }
        {
          type: 'single'
          tag: 'button'
          name: 'del'
          verbose: _("Delete")
          action: $scope.itemDelete
          enable: false
          confirm: _ 'Delete Apply'
          restrict: {
            batch: true
          }
        }
      ]
    }
  .controller "dashboard.application.uncommitedCtr", ($scope, $http,
  $q, $window, $state) ->
    errorTable = new UncommitedApply()
    errorTable.init($scope, {
      $state: $state
      $http: $http
      $window: $window
      $q: $q
    })
    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
    }


class PendingApply extends $unicorn.TableView
  slug: 'pendingApply'
  columnDefs: [
    {
      field: 'request_type_display_name'
      displayName: _("Apply Type")
      cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="dashboard.application.applyId.overview({applyId: item.id})" ng-bind="item[col.field]"></></div>'
    }
    {
      field: 'created_at'
      displayName: _("Created At")
      cellTemplate: '<div class="ngCellText">{{item.created_at | dateLocalize | date: "yyyy-MM-dd HH:mm"}}</div>'
    }
    {
      field: 'state'
      displayName: _("Status")
      cellTemplate: '<div class="ngCellText">{{item.STATUS}}</div>'
    }
  ]
  listData: ($scope, options, dataQueryOpts, callback) ->
    serverUrl = $UNICORN.settings.serverURL
    $http = options.$http
    $q = options.$q
    obj = options.$this
    delete dataQueryOpts.dataFrom
    if dataQueryOpts.dataTo != undefined
      dataQueryOpts['page_size'] = dataQueryOpts['dataTo']
      delete dataQueryOpts.dataTo
    dataQueryOpts['state'] = '1,2,7,8'
    $http.get("#{serverUrl}/workflow-requests", {params: dataQueryOpts})
      .success (res) ->
        if not res
          res =
            list: []
            total: 0
        for wf in res.list
          wfContent = JSON.parse(wf.content)
          wf.display_name = wfContent.request_name
        callback res.list, res.total
      .error (res) ->
        callback []
        toastr.error(_("Failed to get applys!"))

  judgeAction: (action, selectedItems) ->
    restrict = {
      batch: true
      state: null
    }
    for key, value of action.restrict
      restrict[key] = value
    if selectedItems.length == 0
      action.enable = false
      return
    else if selectedItems.length == 1
      if !restrict.state
        action.enable = true
      else
        if restrict.state == selectedItems[0].state
          action.enable = true
        else
          action.enable = false
    else
      if restrict.batch == false
        action.enable = false
        return
      else
        action.enable = true
      if restrict.state
        matchedItems = 0
        for item in selectedItems
          if restrict.state == item.state
            matchedItems += 1
        if matchedItems == selectedItems.length
          action.enable = true
        else
          action.enable = false

  itemChange: (newVal, oldVal, $scope, options) ->
    super newVal, oldVal, $scope, options
    obj = options.$this
    if !$scope.actionButtons.buttons
      return

    for action in $scope.actionButtons.buttons
      if !action.restrict
        continue
      obj.judgeAction(action, $scope.selectedItems)

  initialAction: ($scope, options) ->
    super $scope, options

    obj = options.$this
    $http = options.$http
    $window = options.$window
    $state = options.$state

    $scope.itemDelete = (type, index) ->
      serverURL = $window.$UNICORN.settings.serverURL
      for item, index in $scope.selectedItems
        applyId = item.id
        name = item.display_name || item.request_type_display_name ||applyId
        $http.delete("#{serverURL}/workflow-requests/#{applyId}")
          .success (res) ->
            toastr.success(_("Success delete apply: ") + name)
            $state.go "dashboard.application", {}, {reload: true}
          .error (err) ->
            toastr.error(_("Filed delete apply: ") + name)
            $state.go "dashboard.application", {}, {reload: true}

    $scope.editApply = () ->
      if $scope.selectedItems.length == 1
        apply = $scope.selectedItems[0]
        if apply.state != 3
          return
        serverURL = $window.$UNICORN.settings.serverURL
        applyParam = "#{serverURL}/workflow-requests/#{apply.id}/edit"
        $http.get applyParam
          .success (data, status, headers) ->
            # TODO(ZhengYue): The Edit function in feature
            options.$dataLoader $scope, apply.request_type_name,
            'modal', data["workflow-request"]
          .error (err) ->
            toastr.error _("Failed get detail of apply!")
      else
        return

  judgeStatus: ($scope, item) ->
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
    item.STATUS = $scope.statusMap[item.state]

class ErrorApply extends PendingApply
  slug: 'errorApply'
  columnDefs: [
    {
      field: 'request_type_display_name'
      displayName: _("Apply Type")
      cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="dashboard.application.errorApplyId.overview({errorApplyId: item.id})" ng-bind="item[col.field]"></></div>'
    }
    {
      field: 'created_at'
      displayName: _("Created At")
      cellTemplate: '<div class="ngCellText">{{item.created_at | dateLocalize | date: "yyyy-MM-dd HH:mm"}}</div>'
    }
    {
      field: 'state'
      displayName: _("Status")
      cellTemplate: '<div class="ngCellText">{{item.STATUS}}</div>'
    }
  ]
  listData: ($scope, options, dataQueryOpts, callback) ->
    serverUrl = $UNICORN.settings.serverURL
    $http = options.$http
    $q = options.$q
    obj = options.$this
    delete dataQueryOpts.dataFrom
    if dataQueryOpts.dataTo != undefined
      dataQueryOpts['page_size'] = dataQueryOpts['dataTo']
      delete dataQueryOpts.dataTo
    dataQueryOpts['state'] = '8'
    dataQueryOpts['project_id'] = $UNICORN.person.project.id
    $http.get("#{serverUrl}/workflow-requests", {params: dataQueryOpts})
      .success (res) ->
        if not res
          res =
            list: []
            total: 0
        for wf in res.list
          wfContent = JSON.parse(wf.content)
          wf.display_name = wfContent.request_name
        callback res.list, res.total
      .error (res) ->
        toastr.error(_("Failed to get applys!"))

class ReviewedApply extends PendingApply
  slug: 'reviewedApply'
  columnDefs: [
    {
      field: 'request_type_display_name'
      displayName: _("Apply Type")
      cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="dashboard.application.reviewedApplyId.overview({reviewedApplyId: item.id})" ng-bind="item[col.field]"></></div>'
    }
    {
      field: 'created_at'
      displayName: _("Created At")
      cellTemplate: '<div class="ngCellText">{{item.created_at | dateLocalize | date: "yyyy-MM-dd HH:mm"}}</div>'
    }
    {
      field: 'state'
      displayName: _("Status")
      cellTemplate: '<div class="ngCellText">{{item.STATUS}}</div>'
    }
  ]
  listData: ($scope, options, dataQueryOpts, callback) ->
    serverUrl = $UNICORN.settings.serverURL
    $http = options.$http
    $q = options.$q
    obj = options.$this
    delete dataQueryOpts.dataFrom
    if dataQueryOpts.dataTo != undefined
      dataQueryOpts['page_size'] = dataQueryOpts['dataTo']
      delete dataQueryOpts.dataTo
    dataQueryOpts['state'] = '3,4,5,6'
    dataQueryOpts['project_id'] = $UNICORN.person.project.id
    $http.get("#{serverUrl}/workflow-requests", {params: dataQueryOpts})
      .success (res) ->
        if not res
          res =
            list: []
            total: 0
        for wf in res.list
          wfContent = JSON.parse(wf.content)
          wf.display_name = wfContent.request_name
        callback res.list, res.total
      .error (res) ->
        toastr.error(_("Failed to get applys!"))

class UncommitedApply extends PendingApply
  slug: 'uncommitedApply'
  columnDefs: [
    {
      field: 'request_type_display_name'
      displayName: _("Apply Type")
      cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="dashboard.application.reviewedApplyId.overview({reviewedApplyId: item.id})" ng-bind="item[col.field]"></></div>'
    }
    {
      field: 'created_at'
      displayName: _("Created At")
      cellTemplate: '<div class="ngCellText">{{item.created_at | dateLocalize | date: "yyyy-MM-dd HH:mm"}}</div>'
    }
    {
      field: 'state'
      displayName: _("Status")
      cellTemplate: '<div class="ngCellText">{{item.STATUS}}</div>'
    }
  ]
  listData: ($scope, options, dataQueryOpts, callback) ->
    serverUrl = $UNICORN.settings.serverURL
    $http = options.$http
    $q = options.$q
    obj = options.$this
    delete dataQueryOpts.dataFrom
    if dataQueryOpts.dataTo != undefined
      dataQueryOpts['page_size'] = dataQueryOpts['dataTo']
      delete dataQueryOpts.dataTo
    dataQueryOpts['state'] = '0'
    dataQueryOpts['project_id'] = $UNICORN.person.project.id
    $http.get("#{serverUrl}/workflow-requests", {params: dataQueryOpts})
      .success (res) ->
        if not res
          res =
            list: []
            total: 0
        callback res.list, res.total
      .error (res) ->
        toastr.error(_("Failed to get applys!"))
