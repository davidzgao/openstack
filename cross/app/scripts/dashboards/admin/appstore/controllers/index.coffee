'use strict'

angular.module('Cross.admin.appstore')
  .controller 'admin.appstore.AppstoreCtr', ($scope, $http,
  $window, $q, $state, $interval) ->
    $scope.slug = _ 'App'
    $scope.tabs = [{
      title: _('Unpublish')
      template: 'unpublish.tpl.html'
      enable: false
    }, {
      title: _('Published')
      template: 'published.tpl.html'
      enable: true
    }]

    $scope.currentTab = 'published.tpl.html'

    $scope.onClickTab = (tab) ->
      $scope.currentTab = tab.template
    $scope.isActiveTab = (tabUrl) ->
      return tabUrl == $scope.currentTab

  .controller "admin.appstore.UnpublishCtr", ($scope, $http, $q,
  $window, $state, $interval) ->
    unpublishedTable = new AppTable($scope)
    unpublishedTable.init($scope, {
      $state: $state
      $http: $http
      $window: $window
      $interval: $interval
      $q: $q
    })
    $scope.items = []
    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      buttons: [
        {
          type: 'single'
          tag: 'button'
          name: 'publish'
          verbose: _("Publish")
          action: $scope.publish
          enable: false
          confirm: _ 'Publish'
          restrict: {
            batch: true
          }
        }
      ]
    }
  .controller "admin.appstore.PublishedCtr", ($scope, $http, $q,
  $window, $state, $interval) ->
    $scope.addition = (typeId, enable) ->
      if enable == 0
        enable = 1
      else
        enable = 0
      param = {
        enable: enable
      }
      url = $CROSS.settings.serverURL
      $http.put "#{url}/workflow-request-types/#{typeId}", param
        .success (data, status) ->
          if data
            data = data['workflow-request-type']
            for wf, index in $scope.items
              if wf.id == data.id
                if data.enable == 1
                  wf.ENABLE = _ 'Enable'
                  wf.condition = 'on'
                else
                  wf.condition = 'off'
                  wf.ENABLE = _ 'Disable'
          toastr.success _("Success update app status.")

    publishedTable = new PublishedTable($scope)
    publishedTable.init($scope, {
      $state: $state
      $http: $http
      $window: $window
      $interval: $interval
      $q: $q
    })

    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      buttons: [
        {
          type: 'action'
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

class AppTable extends $cross.TableView
  labileStatus: [
  ]
  slug: 'apps'
  pagingOptions:
    showFooter: false
  columnDefs: [
    {
      field: "image"
      displayName: _("LOGO")
      cellTemplate: '<div lazy-load load-image class="imageCell" url=item.image_url item=item></div>'
    }
    {
      field: "display_name"
      displayName: _("Type Name")
      cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]"></div>'
    }
    {
      field: "resource_type"
      displayName: _("Description")
      cellTemplate: '<div class="ngCellText">{{item.detail}}</div>'
    }
    {
      field: "version_state"
      displayName: _("Version")
      cellTemplate: '<div class="ngCellText">{{item.fit_version}}</div>'
    }
  ]
  listData: ($scope, options, dataQueryOpts, callback) ->
    serverURL = $CROSS.settings.serverURL
    $http = options.$http
    $q = options.$q
    $http.get "#{serverURL}/apps"
      .success (res) ->
        for app in res
          app.image_url = "apps/#{app.id}/image"
          $scope.items.push app
        callback res, res.length

  initialAction: ($scope, options) ->
    $http = options.$http
    serverURL = $CROSS.settings.serverURL

    $scope.publish = () ->
      for app in $scope.selectedItems
        workflow_types = []
        workflowContent = {
          "enable": "0",
          "autoapprove": "0"
        }
        $http.get "#{serverURL}/apps/#{app.id}"
          .success (data, status, headers) ->
            workflowContent.template = data.template
            delete data.template
            workflowContent.content = data
            workflowContent.content.image_url = app.imageData
            workflowContent.name = data.name || "app_#{data.id}"
            workflowContent.version_state = data.fit_version
            workflow_types.push workflowContent
            params = workflow_types
            $http.post "#{serverURL}/workflow-request-types", params
              .success (data, status, headers) ->
                toastr.success _("Success publish app.")
              .error (error) ->
                toastr.error _("Failed to publish app.")

    super $scope, options

  itemChange: (newVal, oldVal, $scope, options) ->
    obj = options.$this
    if newVal != oldVal
      selectedItems = []
      for item in newVal
        if item.isSelected == true
          selectedItems.push item
      $scope.selectedItems = selectedItems

      for action in $scope.actionButtons.buttons
        if !action.restrict
          continue
        obj.judgeAction(action, selectedItems)

  judgeAction: (action, selectedItems) ->
    restrict = {
      batch: true
    }
    for key, value of action.restrict
      restrict[key] = value

    if selectedItems.length == 0
      action.enable = false
      return
    else if selectedItems.length > 0
      if action.restrict.batch
        action.enable = true

class PublishedTable extends $cross.TableView
  slug: 'apps'
  pagingOptions:
    showFooter: false
  addition: true
  columnDefs: [
    {
      field: "image"
      displayName: _("LOGO")
      cellTemplate: '<div lazy-load load-image class="imageCell" url=item.image_url item=item></div>'
    }
    {
      field: "display_name"
      displayName: _("Name")
      cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]"></div>'
    }
    {
      field: "resource_type"
      displayName: _("Description")
      cellTemplate: '<div class="ngCellText">{{item.resource_type}}</div>'
    }
    {
      field: "version_state"
      displayName: _("Version")
      cellTemplate: '<div class="ngCellText">{{item.version_state}}</div>'
    }
    {
      field: "enable"
      displayName: _("Enable")
      cellTemplate: '<div class="switch-button" switch-button status="item.condition" verbose="item.ENABLE" action="addition(item.id, item.enable)" enable="true">{{item.ENABLE}}</div>'
    }
  ]
  listData: ($scope, options, dataQueryOpts, callback) ->
    serverURL = $CROSS.settings.serverURL
    $http = options.$http
    $q = options.$q
    $http.get "#{serverURL}/workflow-request-types"
      .success (res) ->
        for wf_type in res
          if wf_type.enable == 1
            wf_type.ENABLE = _ 'Enable'
            wf_type.condition = 'on'
          else
            wf_type.condition = 'off'
            wf_type.ENABLE = _ 'Disable'
          if wf_type.content
            wf_content = JSON.parse(wf_type.content)
            if wf_content.image_url
              wf_type.imageData = wf_content.image_url
        callback res, res.length

  initialAction: ($scope, options) ->
    $http = options.$http
    serverURL = $CROSS.settings.serverURL

    super $scope, options

  itemChange: (newVal, oldVal, $scope, options) ->
    obj = options.$this
    if newVal != oldVal
      selectedItems = []
      for item in newVal
        if item.isSelected == true
          selectedItems.push item
      $scope.selectedItems = selectedItems

      for action in $scope.actionButtons.buttons
        if !action.restrict
          continue
        obj.judgeAction(action, selectedItems)

  judgeAction: (action, selectedItems) ->
    restrict = {
      batch: true
    }
    for key, value of action.restrict
      restrict[key] = value

    if selectedItems.length == 0
      action.enable = false
      return
    else if selectedItems.length == 1
      action.enable = true
      return
    else if selectedItems.length > 1
      if action.restrict.batch
        action.enable = true
