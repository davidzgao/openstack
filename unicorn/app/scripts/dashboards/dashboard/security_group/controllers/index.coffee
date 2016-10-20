'use strict'

###*
 # @ngdoc function
 # @name Unicorn.dashboard.instance:SecurityGroupCtr
 # @description
 # # SecurityGroupCtr
 # Controller of the Unicorn
###
angular.module("Unicorn.dashboard.security_group")
  .controller "dashboard.security_group.SecurityGroupCtr", ($scope, $http, $q, $window,
                                                               $state, $stateParams) ->
    # Initial note.
    $scope.note =
      secGroup: _("security group")
      buttonGroup:
        create: _("Create")
        delete: _("Delete")
        refresh: _("Refresh")

    (new tableView()).init($scope, {
      $http: $http
      $q: $q
      $window: $window
      $state: $state
      $stateParams: $stateParams
    })

    $scope.itemLinkAction = (link, enable) ->
      $state.go link


    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      searchOpts:
        showSearch: true
        searchKey: 'name'
        searchAction: $scope.search
      buttons: [
        {
          type: 'link'
          tag: 'a'
          name: 'create'
          verbose: $scope.note.buttonGroup.create
          enable: true
          action: $scope.itemLinkAction
          link: 'dashboard.security_group.create'
          needConfirm: true
        }
        {
          type: 'single'
          tag: 'button'
          name: 'delete'
          verbose: $scope.note.buttonGroup.delete
          ngClass: 'batchActionEnableClass'
          action: $scope.deleteSecGroup
          enable: false
          confirm: _ 'Delete'
          needConfirm: true
          restrict: {
            batch: true
          }
        }
      ]
    }


class tableView extends $unicorn.TableView
  slug: 'secGroup'
  showCheckbox: true
  pagingOptions:
    showFooter: false
  paging: false

  columnDefs: [
    {
      field: "name",
      displayName: _("Name"),
      cellTemplate: '<div class="ngCellText enableClick" ng-click="detailShow(item.id)" data-toggle="tooltip" data-placement="top" title="{{item.name}}"><a ui-sref="dashboard.security_group.securityGroupId.overview({ securityGroupId:item.id })" ng-bind="item.name"></a></div>'
    }
    {
      field: "description"
      displayName: _("Description")
      cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]" data-toggle="tooltip" data-placement="top" title="{{item.host}}"></div>'
    }
  ]

  listData: ($scope, options, dataQueryOpts, callback) ->
    serverUrl = $UNICORN.settings.serverURL
    $http = options.$http
    queryOpts = {}
    if $UNICORN.settings.use_neutron
      queryOpts =
        tenant_id: $UNICORN.person.project.id
    $unicorn.networks.listSecurityGroups $http, queryOpts, (err, securityGroups) ->
      if err
        securityGroups = []
        toastr.error _("Failed to get security groups")
      callback securityGroups
    return true

  itemDelete: ($scope, itemId, options, callback) ->
    $http = options.$http
    $window = options.$window
    serverUrl = $UNICORN.settings.serverURL
    $unicorn.networks.securityGroupDelete $http, itemId, (err, rs) ->
      if not err
        callback 200
      else
        callback err.status

  initialAction: ($scope, options) ->
    super $scope, options

    obj = options.$this
    $state = options.$state
    # handle delete action.
    $scope.deleteSecGroup = ->
      obj.action $scope, options, (item, index) ->
        itemId = item.id
        name = item.name || itemId
        obj.itemDelete $scope, itemId, options, (response) ->
          if response != 200
            toastr.error _("Failed to delete security group: ") + name
            return false

          toastr.success _('Successfully delete security group: ') + name
          $state.go "dashboard.security_group", null, {reload: true}

  judgeAction: (action, selectedItems) ->
    #Judge the action button is could click
    restrict = {
      batch: true
      status: null
      resource: null
      attr: null
    }
    for key, value of action.restrict
      restrict[key] = value

    if selectedItems.length == 0
      action.enable = false
      return
    else if selectedItems.length == 1
      if !restrict.status
        action.enable = true
        return
      else
        if restrict.status == selectedItems[0].status
          action.enable = true
        else
          action.enable = false
    else
      if restrict.batch == false
        action.enable = false
        return
      else
        action.enable = true
      if restrict.status
        matchedItems = 0
        for item in selectedItems
          if restrict.status == item.STATUS
            matchedItems += 1
        if matchedItems == selectedItems.length
          action.enable = true
        else
          action.enable = false


  itemChange: (newVal, oldVal, $scope, options) ->
    obj = options.$this
    super newVal, oldVal, $scope, options
    selectedItems = $scope.selectedItems

    for action in $scope.actionButtons.buttons
      if !action.restrict
        continue
      obj.judgeAction(action, selectedItems)
