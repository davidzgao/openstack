'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.project.public_net')
  .controller 'project.public_net.PublicNetCtr', ($scope, $http, $window, $q,
                                         $state, $interval, $templateCache,
                                         $compile, $animate, $gossipService) ->
    $scope.$on '$gossipService.floating_ip', (event, meta) ->
      id = meta.payload.id
      serId = undefined
      changeBind = false
      if meta.isInstance and meta.meta
        ip = meta.meta.floating_ip
        changeBind = true
        if meta.event == 'instance.floating_ip.associate'
          serId = id
      if $scope.nets
        counter = 0
        len = $scope.nets.length
        loop
          break if counter >= len
          if $scope.nets[counter].ip == ip
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
                $scope.nets[counter].instance = nameDict[serId].name
                $scope.nets[counter].instance_id = serId
        if changeBind
          if counter < len
            $scope.nets[counter].instance = null
            $scope.nets[counter].instance_id = null
            $scope.nets[counter].fixed_ip = null

    serverUrl = $window.$CROSS.settings.serverURL

    $scope.note =
      title: _("Public network")
      buttonGroup:
        bind: _("Bind")
        unbind: _("Unbind")
        allocate: _("Allocate")
        reallocate: _("Reallocate")
        refresh: _("Refresh")

    # Category for instance action
    $scope.batchActionEnableClass = 'btn-disable'

    # For sort at table header
    $scope.sort = {
      reverse: false
    }

    # For tabler footer and pagination or filter
    $scope.showFooter = false

    $scope.abnormalStatus = [
      'error'
    ]

    $scope.columnDefs = [
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
    # --End--
    # Category for instance action
    $scope.singleSelectedItem = {}

    # Variates for dataTable
    # --start--

    # For checkbox select
    $scope.AllSelectedItems = false
    $scope.NoSelectedItems = true

    $scope.pagingOptions =
      showFooter: $scope.showFooter

    $scope.filterOptions =
      filterText: '',
      useExternalFilter: true

    $scope.nets = []

    $scope.netsOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      pageMax: 5
    }

    # Function for get paded instances and assign class for
    # element by status
    setPagingData = (pagedData) ->
      $scope.nets = pagedData
      # Compute the total pages
      $scope.netsOpts.data = $scope.nets

    # --End--

    # Functions for handle event from action

    $scope.selectedItems = []
    # TODO(ZhengYue): Add batch action enable/disable judge by status
    $scope.selectChange = () ->
      selectedItems = $scope.selectedItems
      if selectedItems.length == 1
        $scope.NoSelectedItems = false
        $scope.batchActionEnableClass = 'btn-enable'
        $scope.singleSelectedItem = selectedItems[0]
      else if selectedItems.length > 1
        $scope.NoSelectedItems = false
        $scope.batchActionEnableClass = 'btn-enable'
      else
        $scope.NoSelectedItems = true
        $scope.batchActionEnableClass = 'btn-disable'
        $scope.singleSelectedItem = {}
      if selectedItems.length == 1
        if selectedItems[0].instance_id
          $scope.canBind = 'btn-disable'
          $scope.canUnbind = 'btn-enable'
          return true
        $scope.canBind = 'btn-enable'
        $scope.canUnbind = 'btn-disable'
      else
        $scope.canUnbind = 'btn-disable'
        $scope.canBind = 'btn-disable'

    # Functions about interaction with net
    # --Start--

    listDetailedNets = ($http, $window, $q, callback) ->
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

        objQuery = []
        serverHttp = $http.get("#{serverUrl}/servers/query", {
          params:
            ids: JSON.stringify serverIds
            fields: '["name"]'
        })
        objQuery.push serverHttp
        if $CROSS.settings.use_neutron
          objQuery.push $http.get("#{serverUrl}/lb/vips")
        $q.all(objQuery)
          .then (rs) ->
            servers = rs[0].data
            vipIpMap = {}
            if rs[1]
              vips = rs[1].data
              for vip in vips
                vipIpMap[vip.address] = vip.id
            for net in res.data
              if net.instance_id
                if servers[net.instance_id]
                  net.instance = servers[net.instance_id].name
              if vipIpMap[net.fixed_ip]
                net.vip = vipIpMap[net.fixed_ip]
            callback res.data
          , (err) ->
            console.log err, "Failed to get projects/servers name"

    # Function for async list instances
    getPagedDataAsync = (callback) ->
      listDetailedNets $http, $window, $q, (nets) ->
        setPagingData(nets)
        (callback && typeof(callback) == "function") && callback()

    getPagedDataAsync()

    # Callback after instance list change
    netCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for net in newVal
          if net.isSelected == true
            selectedItems.push net
        $scope.selectedItems = selectedItems

    $scope.$watch('nets', netCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    netReallocate = ($http, $window, netId, callback) ->
      $http.delete("#{serverUrl}/os-floating-ips/#{netId}")
        .success (rs) ->
          callback(200)
        .error (err) ->
          callback(err.status)

    # Reallocate selected servers
    $scope.reallocateNet = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        netId = item.id
        name = item.ip || netId
        netReallocate $http, $window, netId, (response) ->
          # TODO(ZhengYue): Add some tips for success or failed
          if response == 200
            toastr.success(_('Successfully reallocate floating ip: ') + name)
            $state.go 'project.public_net', {}, {reload: true}

    serverIpUnbind = (name, serverId, callback) ->
      params =
        instanceId: serverId
        address: name
      $cross.instanceAction "removeFloatingIp", $http, $window, params, callback

    vipIpUnbind = (floatingipId, callback) ->
      params =
        port_id: null

      $cross.floatingipUpdate floatingipId, $http, $window, params, callback

    # handle detaching volume.
    $scope.unbindIp = ->
      selectedItems = $scope.selectedItems
      if not selectedItems or not selectedItems.length
        return
      item = selectedItems[0]
      name = item.ip
      if item.instance_id and not item.vip
        serverId = item.instance_id
        serverIpUnbind name, serverId, (response) ->
          if response != 200
            toastr.error _("Failed to unbind floating ip: ") + name
            return false

        $state.go 'project.public_net', null, {reload: true}
      if item.vip
        floatingipId = item.id
        vipIpUnbind floatingipId, (response) ->

          if response != 200
            toastr.error _("Failed to unbind floating ip: ") + name
            return false

        $state.go 'project.public_net', null, {reload: true}

    $scope.bindIp = () ->
      if $scope.canBind == "btn-enable"
        $state.go 'project.public_net.floatingIpId.bind', {floatingIpId:$scope.selectedItems[0].ip}

    $scope.refresResource = (resource) ->
      $scope.netsOpts.data = null
      getPagedDataAsync()
