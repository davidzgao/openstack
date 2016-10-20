'use strict'

###*
 # @ngdoc function
 # @name Unicorn.dashboard.instance:KeypairCtr
 # @description
 # # KeypairCtr
 # Controller of the Unicorn
###
angular.module("Unicorn.dashboard.keypair")
  .controller "dashboard.keypair.KeypairCtr", ($scope, $http, $q,
  $window, $state, $interval, $stateParams) ->

    keypairTable = new KeypairTable()
    keypairTable.init($scope, (
      $http: $http
      $q: $q
      $window: $window
      $interval: $interval
      $state: $state
      $stateParams: $stateParams
    ))

    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      buttons: [
        {
          type: 'single'
          tag: 'a'
          name: 'create'
          action: $scope.itemCreate
          link: 'dashboard.keypair.create'
          verbose: _("Create")
          enable: true
        }
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

class KeypairTable extends $unicorn.TableView
  slug: 'keypair'
  labileStatus: [
    'creating'
    'error_deleting'
    'deleting'
    'attaching'
    'detaching'
    'downloading'
  ]
  columnDefs: [
    {
      field: "name",
      displayName: _("Name"),
      cellTemplate: '<div class="ngCellText" data-toggle="tooltip" data-placement="top" title="{{item.name}}" ng-bind="item.name"></div>'
    }
    {
      field: "fingerprint"
      displayName: _("Fingerprint")
      cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]" data-toggle="tooltip" data-placement="top" title="{{item.host}}"></div>'
    }
  ]
  listData: ($scope, options, dataQueryOpts, callback) ->
    $window = options.$window
    $http = options.$http
    serverUrl = $window.$UNICORN.settings.serverURL
    $http.get("#{serverUrl}/os-keypairs").success (keys) ->
      if not keys
        res =
          data: []
      else
        res =
          data: keys

      callback res.data

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
        keyId = item.id
        name = item.name || keyId
        $http.delete("#{serverURL}/os-keypairs/#{keyId}")
          .success (res) ->
            toastr.success(_("Success delete secret key: ") + name)
            $state.go 'dashboard.keypair', {}, {reload: true}
          .error (err) ->
            toastr.error(_("Failed delete secret key: ") + name)

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

    for action in $scope.actionButtons.buttons
      if !action.restrict
        continue
      obj.judgeAction(action, $scope.selectedItems)
