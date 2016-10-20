'use strict'
###*
 # @ngdoc function
 # @name Unicorn.dashboard.instance:FloatingIpCtr
 # @description
 # # FloatingIpCtr
 # Controller of the Unicorn
###
angular.module("Unicorn.dashboard.floatingIp")
  .controller "dashboard.floatingIp.FloatingIpCtr", ($scope, $http,
  $gossipService, $q, $window, $state, $stateParams, $dataLoader, tryApply) ->
    # Initial note.
    $scope.note =
      floatingIp: _("floating IP")
      buttonGroup:
        bind: _("Bind")
        unbind: _("Unbind")
        applyFloatingIp: _("Apply floating IP")
        delete: _("Delete")
        refresh: _("Refresh")

    (new tableView()).init($scope, {
      $http: $http
      $q: $q
      $window: $window
      $state: $state
      $stateParams: $stateParams
      $gossipService: $gossipService
      $dataLoader: $dataLoader
      $tryApply: tryApply
    })

    $scope.itemLinkAction = (link, enable) ->
      if enable != 'enabled'
        return false
      if $scope.selectedItems.length != 1
        return
      $state.go link, {floatingIpId: $scope.selectedItems[0].ip}

    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      buttons: [
        {
          type: 'single'
          tag: 'button'
          name: 'create'
          verbose: $scope.note.buttonGroup.applyFloatingIp
          enable: true
          action: $scope.tryApply
          needConfirm: true
        }
        {
          type: 'link'
          tag: 'a'
          name: 'bind'
          verbose: $scope.note.buttonGroup.bind
          ngClass: 'batchActionEnableClass'
          action: $scope.itemLinkAction
          link: 'dashboard.floatingIp.floatingIpId.bind'
          enable: false
          confirm: _ 'Bind'
          restrict: {
            binded: false
          }
        }
        {
          type: 'single'
          tag: 'button'
          name: 'unbind'
          verbose: $scope.note.buttonGroup.unbind
          ngClass: 'batchActionEnableClass'
          action: $scope.unbindIp
          enable: false
          confirm: _ 'Unbind'
          needConfirm: true
          restrict: {
            binded: true
          }
        }
        {
          tag: 'button'
          name: 'delete'
          verbose: $scope.note.buttonGroup.delete
          enable: false
          type: 'action'
          ngClass: 'batchActionEnableClass'
          action: $scope.deleteFloatingIp
          needConfirm: true
          confirm: _ 'Delete'
          restrict: {
            batch: true
          }
        }
      ]
    }


class tableView extends $unicorn.TableView
  slug: 'floatingIp'
  showCheckbox: true
  pagingOptions:
    showFooter: false
  paging: false
  columnDefs: [
    {
      field: "ip",
      displayName: _("Public IP address"),
      cellTemplate: '<div class="ngCellText" data-toggle="tooltip" data-placement="top" title="{{item.ip}}" ng-bind="item.ip"></div>'
    }
    {
      field: "instance"
      displayName: _("Server")
      cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]" data-toggle="tooltip" data-placement="top" title="{{item.host}}"></div>'
    }
    {
      field: "fixed_ip"
      displayName: _("Inner Ip address")
      cellTemplate: '<div class="ngCellText" ng-bind="item[col.field]" data-toggle="tooltip" data-placement="top" title="{{item.host}}"></div>'
    }
    {
      field: "pool"
      displayName: _("IP pool")
      cellTemplate: '<div ng-bind="item[col.field]"></div>'
    }
  ]

  listData: ($scope, options, dataQueryOpts, callback) ->
    serverUrl = $UNICORN.settings.serverURL
    $http = options.$http
    $q = options.$q
    $http.get("#{serverUrl}/os-floating-ips").success (nets) ->
      if not nets
        res =
          data: []
      else
        res =
          data: nets

      serverIds = []
      for net in res.data
        if net.fixed_ip == 'null' or not net.fixed_ip
          net.fixed_ip = ''
        if net.instance_id != 'null' and net.instance_id
          serverIds.push net.instance_id
        else
          net.instance_id = ''

      serverHttp = $http.get("#{serverUrl}/servers/query", {
        params:
          ids: JSON.stringify serverIds
          fields: '["name"]'
      })
      $q.all([
        serverHttp
      ])
        .then (rs) ->
          servers = rs[0].data
          for net in res.data
            if net.instance_id
              if not servers[net.instance_id]
                continue
              net.instance = servers[net.instance_id].name
          callback res.data
        , (err) ->
          callback []
          toastr.error _("Failed to get servers name")
    return true

  itemDelete: ($scope, itemId, options, callback) ->
    $http = options.$http
    $window = options.$window
    serverUrl = $UNICORN.settings.serverURL
    $http.delete "#{serverUrl}/os-floating-ips/#{itemId}"
      .success ->
        callback 200
      .error (err, status) ->
        callback status

  itemUnbind: ($scope, ip, serverId, options, callback) ->
    $http = options.$http
    $window = options.$window
    params =
      instanceId: serverId
      address: ip
    $unicorn.instanceAction "removeFloatingIp", $http, $window, params, callback

  initialAction: ($scope, options) ->
    $scope.$on '$gossipService.floating_ip', (event, meta) ->
      id = meta.payload.id
      serId = undefined
      changeBind = false
      serverUrl = $UNICORN.settings.serverURL
      if meta.isInstance and meta.meta
        ip = meta.meta.floating_ip
        changeBind = true
        if meta.event == 'instance.floating_ip.associate'
          serId = id
      if $scope.items
        counter = 0
        len = $scope.items.length
        loop
          break if counter >= len
          if $scope.items[counter].ip == ip
            break
          counter += 1
        if serId
          ids = [serId]
          params =
            params:
              ids: JSON.stringify ids
              fields: '["name"]'
          $http.get "#{serverUrl}/servers/query", params
            .success (nameDict) ->
              if counter < len
                nameDict = nameDict || {}
                $scope.items[counter].instance = nameDict[serId].name
                $scope.items[counter].instance_id = serId
        if changeBind
          if counter < len
            $scope.items[counter].instance = null
            $scope.items[counter].instance_id = null
            $scope.items[counter].fixed_ip = null
    super $scope, options

    obj = options.$this
    $state = options.$state
    $scope.canBind = 'btn-disable'
    $scope.canUnbind = 'btn-disable'
    # handle delete action.
    $scope.deleteFloatingIp = ->
      obj.action $scope, options, (item, index) ->
        itemId = item.id
        name = item.ip || itemId
        obj.itemDelete $scope, itemId, options, (response) ->
          if response != 200
            toastr.error _("Failed to delete floating ip: ") + name
            return false
          toastr.success _('Successfully delete floating ip: ') + name
          $state.go 'dashboard.floatingIp', {}, {reload: true}

    # handle detaching volume.
    $scope.unbindIp = (type, index) ->
      obj.action $scope, options, (item, index) ->
        name = item.ip
        serverId = item.instance_id
        obj.itemUnbind $scope, name, serverId, options, (response) ->
          if response != 200
            toastr.error _("Failed to unbind floating ip: ") + name
            return false
          else
            toastr.success _("Successfully unbind floating ip: ") + name

          $state.go 'dashboard.floatingIp', null, {reload: true}

    $scope.dataLoading = false
    $scope.applyFloating = () ->
      if $scope.dataLoading
        return
      $http = options.$http
      serverUrl = $UNICORN.settings.serverURL
      workflowTypesURL = "#{serverUrl}/workflow-request-types"
      $http.get workflowTypesURL
        .success (data) ->
          if !$unicorn.wfTypesMap
            $unicorn.wfTypesMap = {}
          for wfType in data
            $unicorn.wfTypesMap[String(wfType.id)] = wfType.name
            if wfType.name == 'create_floating_ip'
              floatingIPReq = String(wfType.id)
          if floatingIPReq
            $scope.dataLoading = true
            options.$dataLoader($scope, floatingIPReq, 'modal')
        .error (err) ->
          toastr.error _("Error at load apply types.")

    $scope.tryApply = () ->
      options['type'] = 'floating_ips'
      options['service'] = 'nova'
      options['callback'] = $scope.applyFloating
      options['projectId'] = $UNICORN.person.project.id
      options['serverUrl'] = $UNICORN.settings.serverURL
      options['useNeutron'] = true if $UNICORN.settings.use_neutron
      options.$tryApply options

  judgeAction: (action, selectedItems) ->
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
      if restrict.binded == !!selectedItems[0].fixed_ip
        # if it was binded(the !! symbol is used to get a Boolean value)
        action.enable = true
        return
      else if !restrict.status && restrict.binded == undefined
        action.enable = true
        return
      else
        if restrict.status == selectedItems[0].status
          action.enable = true
        else
          action.enable = false
    else
      if restrict.batch == true
        action.enable = true
        return
      action.enable = false

    if restrict.resource
      matchedItems = 0
      for item in selectedItems
        if item[restrict.resource] and item[restrict.resource].length > 0
          matchedItems += 1
      if matchedItems == selectedItems.length
        action.enable = true
      else
        action.enable = false

    if restrict.attr
      matchedItems = 0
      for item in selectedItems
        if item[restrict.attr]
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
