'use strict'

###*
 # @ngdoc function
 # @name Unicorn.dashboard.instance:FeedbackCtr
 # @description
 # # FeedbackCtr
 # Controller of the Unicorn
###
angular.module("Unicorn.dashboard.feedback")
  .controller "dashboard.feedback.FeedbackCtr", ($scope, $tabs) ->
    $scope.tabs = [{
      title: _('Untreated')
      template: 'untreated.feedback.html'
      enable: true
      slug: 'untreated'
    }, {
      title: _('Processing')
      template: 'processing.feedback.html'
      enable: true
      slug: 'processing'
    }, {
      title: _('Closed')
      template: 'closed.feedback.html'
      enable: true
      slug: 'closed'
    }]

    $scope.currentTab = 'untreated.feedback.html'
    $tabs $scope, 'dashboard.feedback'
  .controller "dashboard.feedback.untreatedCtr", ($scope, $http,
  $q, $window, $state, $interval) ->
    untreatedTable = new UntreatedFeedback()
    untreatedTable.init($scope, {
      $state: $state
      $http: $http
      $window: $window
      $q: $q
    })
    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      buttons: [
        {
          type: 'single'
          tag: 'a'
          name: 'create'
          action: $scope.itemCreate
          link: 'dashboard.feedback.create'
          verbose: _("Create")
          enable: true
        }
        {
          type: 'single'
          tag: 'button'
          name: 'del'
          verbose: _("Close")
          action: $scope.itemDelete
          enable: false
          confirm: _ 'Close'
          restrict: {
            batch: true
          }
        }
      ]
    }
  .controller "dashboard.feedback.processingCtr", ($scope, $http,
  $q, $window, $state, $interval) ->
    processingTable = new ProcessingFeedback()
    processingTable.init($scope, {
      $state: $state
      $http: $http
      $window: $window
      $q: $q
    })
    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      buttons: [
        {
          type: 'single'
          tag: 'button'
          name: 'del'
          verbose: _("Close")
          action: $scope.itemDelete
          enable: false
          confirm: _ 'Close'
          restrict: {
            batch: true
          }
        }
      ]
    }
  .controller "dashboard.feedback.closedCtr", ($scope, $http,
  $q, $window, $state, $interval) ->
    closedTable = new ClosedFeedback()
    closedTable.init($scope, {
      $state: $state
      $http: $http
      $window: $window
      $q: $q
    })
    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      buttons: []
    }

class UntreatedFeedback extends $unicorn.TableView
  slug: 'untreatedFeedback'
  columnDefs: [
    {
      field: 'title'
      displayName: _("Title")
      cellTemplate: '<div class="ngCellText enableClick"><a ui-sref="dashboard.feedback.feedbackId.overview({feedbackId: item.id})" ng-bind="item[col.field]"></a></div>'
    }
    {
      field: 'content'
      displayName: _("Content")
      cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]"></div>'
    }
    {
      field: 'updated_at'
      displayName: _("Update At")
      cellTemplate: '<div class="ngCellText" >{{item[col.field] | dateLocalize | date:"yyyy-MM-dd HH:mm"}}</div>'
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
    dataQueryOpts['state'] = 0
    dataQueryOpts['project_id'] = $UNICORN.person.project.id
    $http.get("#{serverUrl}/feedbacks", {params: dataQueryOpts})
      .success (res) ->
        if not res
          res =
            list: []
            total: 0
        callback res.list, res.total
      .error (res) ->
        callback []
        toastr.error(_("Failed to get feedbacks!"))

  judgeAction: (action, selectedItems) ->
    restrict = {
      batch: true
    }
    for key, value of action.restrict
      restrict[key] = value
    if selectedItems.length == 0
      action.enable = false
      return
    else
      action.enable = true

  itemChange: (newVal, oldVal, $scope, options) ->
    super newVal, oldVal, $scope, options
    obj = options.$this

    if !$scope.actionButtons
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

    $scope.itemCreate = (link) ->
      $state.go link

    $scope.itemDelete = (type, index) ->
      serverURL = $window.$UNICORN.settings.serverURL
      for item, index in $scope.selectedItems
        feedbackId = item.id
        name = item.title || feedbackId
        state = {state: 2}
        $http.put("#{serverURL}/feedbacks/#{feedbackId}", state)
          .success (res) ->
            toastr.success(_("Success close feedback: ") + name)
            $scope.fresh()
          .error (err) ->
            toastr.error(_("Filed close feedback: ") + name)

class ProcessingFeedback extends UntreatedFeedback
  slug: 'processingFeedback'
  listData: ($scope, options, dataQueryOpts, callback) ->
    serverUrl = $UNICORN.settings.serverURL
    $http = options.$http
    $q = options.$q
    obj = options.$this
    delete dataQueryOpts.dataFrom
    if dataQueryOpts.dataTo != undefined
      dataQueryOpts['page_size'] = dataQueryOpts['dataTo']
      delete dataQueryOpts.dataTo
    dataQueryOpts['state'] = 1
    dataQueryOpts['project_id'] = $UNICORN.person.project.id
    $http.get("#{serverUrl}/feedbacks", {params: dataQueryOpts})
      .success (res) ->
        if not res
          res =
            list: []
            total: 0
        callback res.list, res.total
      .error (res) ->
        toastr.error(_("Failed to get feedbacks!"))

class ClosedFeedback extends UntreatedFeedback
  slug: 'closedFeedback'
  listData: ($scope, options, dataQueryOpts, callback) ->
    serverUrl = $UNICORN.settings.serverURL
    $http = options.$http
    $q = options.$q
    obj = options.$this
    delete dataQueryOpts.dataFrom
    if dataQueryOpts.dataTo != undefined
      dataQueryOpts['page_size'] = dataQueryOpts['dataTo']
      delete dataQueryOpts.dataTo
    dataQueryOpts['state'] = 2
    dataQueryOpts['project_id'] = $UNICORN.person.project.id
    $http.get("#{serverUrl}/feedbacks", {params: dataQueryOpts})
      .success (res) ->
        if not res
          res =
            list: []
            total: 0
        callback res.list, res.total
      .error (res) ->
        toastr.error(_("Failed to get feedbacks!"))
