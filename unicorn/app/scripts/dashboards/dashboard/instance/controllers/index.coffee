'use strict'

###*
 # @ngdoc function
 # @name Unicorn.dashboard.instance:InstanceCtr
 # @description
 # # InstanceCtr
 # Controller of the Unicorn
###
angular.module("Unicorn.dashboard.instance")
  .controller "dashboard.instance.InstanceCtr", ($scope, $http, $q,
  $window, $state, $interval, $gossipService, $dataLoader, $stateParams, tryApply) ->
    $scope.tabs = [{
      title: _("Instance")
      template: "exist.html"
      enable: true
    }, {
      title: _("Recycle Bin")
      template: "soft_deleted.html"
      enable: false
    }]

    recycle = $window.$UNICORN.settings.instanceRecycle
    applyTime = $window.$UNICORN.settings.enable_apply_time
    if !applyTime and recycle == "true"
      $scope.tabs[1].enable = true

    $scope.currentTab = $scope.tabs[0]['template']
    $scope.isActiveTab = (tabUrl) ->
      return tabUrl == $scope.currentTab
    $scope.onClickTab = (tab) ->
      params = null
      if tab.template == 'soft_deleted.html'
        params = {tab: 'soft_deleted'}
      $state.go "dashboard.instance", params, {inherit: false}
    if $stateParams.tab == 'soft_deleted'
      $scope.currentTab = "soft_deleted.html"
    else
      $scope.currentTab = "exist.html"

  .controller "dashboard.instance.DeletedInstanceCtr" , ($scope, $http, $q,
  $window, $state, $interval, $gossipService, $dataLoader) ->
    $scope.buttonGroup = {
      refresh: _("Refresh")
      delete: _("Delete")
      restore: _("Restore")
    }
    $scope.statusFilters = {
      key: 'status'
      values: [
        {
          verbose: _("ALL")
          value: "all"
        }
        {
          verbose: _("ACTIVE")
          value: "ACTIVE"
        }
        {
          verbose: _("SHUTOFF")
          value: "SHUTOFF"
        }
        {
          verbose: _("ERROR")
          value: "ERROR"
        }
      ]
    }
    $scope.columnDefs = [
      {
        field: "name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText enableClick" ng-click="detailShow(item.id)" data-toggle="tooltip" data-placement="top" title="{{item.name}}"><a ui-sref="dashboard.instance.instanceId.overview({ instanceId:item.id })" ng-bind="item[col.field]"></a></div>'
      }
      {
        field: "fixed",
        displayName: _("FixedIP"),
        cellTemplate: '<div class="ngCellText" ng-click="test(col)"><li ng-repeat="ip in item.fixed">{{ip | parseNull}}</li><div class="more-in-cell" title={{showAll}} ng-if="item.fixed.length>1"ng-click="cellOpen($event.currentTarget)"></div></div>'
      }
      {
        field: "floating",
        displayName: _("FloatingIP"),
        cellTemplate: '<div class=ngCellText ng-click="test(row, col, $event)"><li ng-repeat="ip in item.floating">{{ip}}</li><li ng-if="item.floating.length==0">{{null | parseNull}}</li></div>'
      }
      {
        field: "image_name",
        displayName: _("Image"),
        cellTemplate: '<div class=ngCellText>{{ item.image_name | parseNull}}</div>'
      }
      {
        field: "vcpus",
        displayName: "CPU",
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
      {
        field: "ram",
        displayName: _("RAM (GB)"),
        cellTemplate: '<div ng-bind="item[col.field] | unitSwitch"></div>'
      }
      {
        field: "created",
        displayName: _("Create At"),
        cellTemplate: '<div>{{item[col.field] | dateLocalize | date:"yyyy-MM-dd HH:mm" }}</div>'
      }
      {
        field: "status",
        displayName: _("Status"),
        cellTemplate: '<div class="ngCellText status" ng-class="item.labileStatus"><i></i>{{item.status}}</div>'
        showFilter: true
        filters: $scope.statusFilters
      }
    ]

    if $UNICORN.settings.enable_apply_time != false
      $scope.columnDefs.push({
        field: "remaining",
        displayName: _("Time Remaining"),
        cellTemplate: '<div left-time time=item.remaining status=item.STATUS>{{ item.remaining }}</div>'
      })

    deletedInstanceTable = new DeletedInstanceTable($scope)
    deletedInstanceTable.additionQueryOpts = {
      tenant_id: $UNICORN.person.project.id
    }

    deletedInstanceTable.filterAction = (key, values) ->
      for value in values
        if value.selected == true
          $scope.filter(key, value.value)
          break

    deletedInstanceTable.init($scope, {
      $state: $state
      $http: $http
      $window: $window
      $interval: $interval
      $q: $q
      $gossipService: $gossipService
      $dataLoader: $dataLoader
    })

    $scope.actionButtons = {
      hasMore: false
      fresh: $scope.fresh
      searchOpts:
        showSearch: false
        searchKey: 'name'
        searchAction: $scope.search
      buttons: [
        {
          type: 'single'
          tag: 'button'
          name: 'restore'
          verbose: $scope.buttonGroup.restore
          enable: false
          confirm: _ "Restore"
          action: $scope.itemAction
          needConfirm: true
          restrict: {
            batch: false
            status: 'SOFT_DELETED'
          }
        }
        {
          type: 'single'
          tag: 'button'
          name: 'delete'
          verbose: $scope.buttonGroup.delete
          ngClass: 'batchActionEnableClass'
          action: $scope.itemDelete
          enable: false
          confirm: _ 'Delete'
          needConfirm: true
          restrict: {
            batch: true
            status: 'SOFT_DELETED'
          }
        }
      ]
    }



  .controller "dashboard.instance.ExistInstanceCtr", ($scope, $http, $q,
  $window, $state, $interval, $gossipService, $dataLoader, tryApply) ->

    $scope.buttonGroup = {
      console: _("VNC Console")
      delete: _("Delete")
      turnOn: _("Turn On")
      turnOff: _("Turn Off")
      more: _("More Action")
      refresh: _("Refresh")
      apply: _("Apply Instance")
    }

    $scope.statusFilters = {
      key: 'status'
      values: [
        {
          verbose: _("ALL")
          value: "all"
        }
        {
          verbose: _("ACTIVE")
          value: "ACTIVE"
        }
        {
          verbose: _("SHUTOFF")
          value: "SHUTOFF"
        }
        {
          verbose: _("ERROR")
          value: "ERROR"
        }
      ]
    }

    $scope.columnDefs = [
      {
        field: "name",
        displayName: _("Name"),
        cellTemplate: '<div class="ngCellText enableClick" ng-click="detailShow(item.id)" data-toggle="tooltip" data-placement="top" title="{{item.name}}"><a ui-sref="dashboard.instance.instanceId.overview({ instanceId:item.id })" ng-bind="item[col.field]"></a></div>'
      }
      {
        field: "fixed",
        displayName: _("FixedIP"),
        cellTemplate: '<div class="ngCellText" ng-click="test(col)"><li ng-repeat="ip in item.fixed">{{ip | parseNull}}</li><div class="more-in-cell" title={{showAll}} ng-if="item.fixed.length>1"ng-click="cellOpen($event.currentTarget)"></div></div>'
      }
      {
        field: "floating",
        displayName: _("FloatingIP"),
        cellTemplate: '<div class=ngCellText ng-click="test(row, col, $event)"><li ng-repeat="ip in item.floating">{{ip}}</li><li ng-if="item.floating.length==0">{{null | parseNull}}</li></div>'
      }
      {
        field: "image_name",
        displayName: _("Image"),
        cellTemplate: '<div class=ngCellText>{{ item.image_name | parseNull}}</div>'
      }
      {
        field: "vcpus",
        displayName: "CPU",
        cellTemplate: '<div ng-bind="item[col.field]"></div>'
      }
      {
        field: "ram",
        displayName: _("RAM (GB)"),
        cellTemplate: '<div ng-bind="item[col.field] | unitSwitch"></div>'
      }
      {
        field: "created",
        displayName: _("Create At"),
        cellTemplate: '<div>{{item[col.field] | dateLocalize | date:"yyyy-MM-dd HH:mm" }}</div>'
      }
      {
        field: "status",
        displayName: _("Status"),
        cellTemplate: '<div class="ngCellText status" ng-class="item.labileStatus"><i></i>{{item.status}}</div>'
        showFilter: true
        filters: $scope.statusFilters
      }
    ]

    if $UNICORN.settings.enable_apply_time != false
      $scope.columnDefs.push({
        field: "remaining",
        displayName: _("Time Remaining"),
        cellTemplate: '<div left-time time=item.remaining status=item.STATUS>{{ item.remaining }}</div>'
      })

    instanceTable = new InstanceTable($scope)
    instanceTable.additionQueryOpts = {
      tenant_id: $UNICORN.person.project.id
    }

    instanceTable.filterAction = (key, values) ->
      for value in values
        if value.selected == true
          $scope.filter(key, value.value)
          break

    instanceTable.init($scope, {
      $state: $state
      $http: $http
      $window: $window
      $interval: $interval
      $q: $q
      $gossipService: $gossipService
      $dataLoader: $dataLoader
      $tryApply: tryApply
    })

    # NOTE(ZhengYue): Update log at: 2015-04-23 17:58
    # Remove the resize function of instance at user dashboard.
    # Because of flavor create be limited by policy at nova,
    # non-administrators can't resize the instance via new flavor.
    # TODO(ZhengYue): Add workflow for resize instance.
    $scope.actionButtons = {
      hasMore: true
      fresh: $scope.fresh
      searchOpts:
        showSearch: true
        searchKey: 'name'
        searchAction: $scope.search
      buttons: [
        {
          type: 'single'
          tag: 'button'
          name: 'create'
          verbose: $scope.buttonGroup.apply
          enable: true
          action: $scope.tryApply
          needConfirm: true
        }
        {
          type: 'single'
          tag: 'button'
          name: 'poweron'
          verbose: $scope.buttonGroup.turnOn
          ngClass: 'batchActionEnableClass'
          action: $scope.itemAction
          enable: false
          confirm: _ 'Power On'
          restrict: {
            batch: true
            status: 'SHUTOFF'
          }
        }
        {
          type: 'single'
          tag: 'button'
          name: 'poweroff'
          verbose: $scope.buttonGroup.turnOff
          ngClass: 'batchActionEnableClass'
          action: $scope.itemAction
          enable: false
          confirm: _ 'Power Off'
          restrict: {
            batch: true
            status: 'ACTIVE'
          }
        }
      ]
      buttonGroup:  [
        {
          name: 'reboot'
          verbose: _('Reboot')
          enable: false
          action: $scope.itemAction
          type: 'action'
          confirm: _ 'Reboot'
          addition:
            message: _('Hard Reboot')
            default: false
            choicees: ['SOFT', 'HARD']
          restrict: {
            batch: true
            status: 'ACTIVE'
          }
        }
        {
          name: 'snapshot'
          verbose: _("Create Backup")
          enable: false
          type: 'link'
          action: $scope.itemLinkAction
          link: 'dashboard.instance.instId.snapshot'
          restrict: {
            batch: false
          }
        }
        {
          name: 'addFloatingIp'
          verbose: _("Attach FloatingIP")
          enable: false
          type: 'link'
          action: $scope.itemLinkAction
          link: 'dashboard.instance.instId.bindIp'
          restrict: {
            batch: false
            status: 'ACTIVE'
          }
        }
        {
          name: 'removeFloatingIp'
          verbose: _("Detach FloatingIP")
          enable: false
          type: 'link'
          action: $scope.itemLinkAction
          link: 'dashboard.instance.instId.unbindIp'
          restrict: {
            batch: false
            status: 'ACTIVE'
            resource: 'floating'
          }
        }
        {
          name: 'attach_volume'
          verbose: _("Attach Volume")
          enable: false
          type: 'link'
          action: $scope.itemLinkAction
          link: 'dashboard.instance.instId.attachVolume'
          restrict: {
            batch: false
            status: 'ACTIVE'
          }
        }
        {
          name: 'detach_volume'
          verbose: _("Detach Volume")
          enable: false
          type: 'link'
          action: $scope.itemLinkAction
          link: 'dashboard.instance.instId.detachVolume'
          restrict: {
            batch: false
            status: 'ACTIVE'
            resource: 'volumes'
          }
        }
        {
          name: 'delete'
          verbose: _("Delete")
          enable: false
          type: 'action'
          action: $scope.itemDelete
          confirm: _ 'Delete'
          restrict: {
            batch: true
          }
        }
      ]
    }

    $scope.desktop =
      show: true
      button: _("Desktop")
      allow_ssh: false
      allow_rdp: false
      classes: 'btn-disable'
      desk_url: "#/dashboard/instance"
      use_rdp: _("RDP Login")
      use_ssh: _("SSH Login")

    # If cloud_desktop not set, we do not need to set desktop button
    cloud_desktop = $UNICORN.settings.cloud_desktop
    if not cloud_desktop
      $scope.desktop.show = false

    if $UNICORN.settings.enable_apply_time != false
      $scope.actionButtons.buttons.push({
          name: 'prolong_time'
          verbose: _("Extend Time")
          enable: true
          tag: 'button'
          type: 'single'
          action: $scope.extendTime
          needConfirm: true
        })

class DeletedInstanceTable extends $unicorn.TableView
  abnormalStatus: [
    'ERROR'
  ]
  shutdowStatus: [
    'PAUSED'
    'SUSPENDED'
    'STOPPED'
    'SHUTOFF'
  ]
  labileStatus: [
    'deleting'
    'BUILD'
    'REBOOT'
    'MIGRATING'
    'HARD_REBOOT'
    'powering-on'
    'powering-off'
    'image_pending_upload'
  ]
  sortOpts: {
    sortingOrder: 'created'
    reverse: true
  }
  listData: ($scope, options, query, callback) ->
    $http = options.$http
    $window = options.$window
    $q = options.$q
    query['status'] = "SOFT_DELETED"
    $unicorn.listDetailedServers($http, $window, $q, query, callback)
  slug: 'deletedInstances'
  labileInstanceQueue: {}

  itemGet: (itemId, options, callback) ->
    $http = options.$http
    $q = options.$q
    $unicorn.serverGet $http, $q, itemId, callback

  getLabileData: ($scope, itemId, options) ->
    obj = options.$this
    # Confirm the task unique for one instance
    if obj.labileInstanceQueue[itemId]
      return
    else
      obj.labileInstanceQueue[itemId] = true

    $interval = options.$interval
    update = () ->
      obj.itemGet itemId, options, (instance) ->
        if instance
          if instance.task_state == null or\
          instance.task_state == 'null'
            $interval.cancel(freshData)
            delete obj.labileInstanceQueue[itemId]
          if instance.STATUS not in obj.labileStatus and\
          instance.task_state == 'null'
            $interval.cancel(freshData)
            delete obj.labileInstanceQueue[itemId]

          for row, index in $scope.items
            if row and row.id == instance.id
              obj.judgeStatus $scope, instance, options
              instance.isSelected = $scope.items[index].isSelected
              $scope.items[index] = instance
              if instance.STATUS == 'ACTIVE'
                $scope.items.splice(index, 1)
        else
          for row, index in $scope.items
            if row.id == itemId
              $scope.items.splice(index, 1)

    freshData = $interval(update, obj.REFRESH_ROW_TIMEOUT)
    update()

    if (!$.intervalList)
      $.intervalList = []
    $.intervalList.push(freshData)

  judgeStatus: ($scope, item, options) ->
    obj = options.$this
    if item.status in obj.labileStatus
      item.labileStatus = 'unknwon'
    else if item.status in obj.shutdowStatus
      item.labileStatus = 'stoped'
    else if item.status in obj.abnormalStatus
      item.labileStatus = 'abnormal'
    else
      item.labileStatus = 'active'

    item.STATUS = item.status
    item.status = _(item.status)

    if item.task_state and item.task_state != 'null'
      item.labileStatus = 'unknwon'
      if item.STATUS == 'ACTIVE' or item.STATUS == 'active'
        item.status = _(item.task_state)
      if item.STATUS == 'SHUTOFF' or item.STATUS == 'shutoff'\
      and item.task_state != 'null'
        item.status = _(item.task_state)
      if item.STATUS == 'SUSPENDED' or item.STATUS == 'SUSPENDED'\
      and item.task_state != 'null'
        item.status = _(item.task_state)

  initialAction: ($scope, options) ->
    # Handle message from gossip.
    $scope.$on '$gossipService.instance', (event, meta) ->
      id = meta.payload.id
      $unicorn.serverGet options.$http, options.$q, id, (instance) ->
        if $scope.items
          counter = 0
          len = $scope.items.length
          loop
            break if counter >= len
            if $scope.items[counter].id == id
              break
            counter += 1
          if not instance
            $scope.items.splice counter, 1
            return
          if options.$this.judgeStatus
            options.$this.judgeStatus $scope, instance, options
            $scope.items[counter] = instance

    super $scope, options
    obj = options.$this
    $http = options.$http
    $window = options.$http
    $state = options.$state
    $scope.itemAction = (type, index) ->
      actionName = $scope.actionButtons[type][index].name
      addition = ''
      verbose = $scope.actionButtons[type][index].verbose
      angular.forEach $scope.selectedItems, (instance, index) ->
        instanceId = instance.id
        message =
          object: "instance-#{instanceId}"
          priority: 'info'
          loading: 'true'
          content: _(["Instance %s is %s ...", instance.name, verbose])
        options.$gossipService.receiveMessage message
        $unicorn.instanceAction actionName, $http, $window,
        {'instanceId': instanceId, addition: addition}, (response) ->
          if response
            obj.getLabileData $scope, instanceId, options

    $scope.itemDelete = () ->
      angular.forEach $scope.selectedItems, (instance, index) ->
        instanceId = instance.id
        message =
          object: "instance-#{instanceId}"
          priority: 'info'
          loading: 'true'
          content: _(["Instance %s is %s ...", instance.name, _("deleting")])
        options.$gossipService.receiveMessage message
        $unicorn.serverDelete $http, $window, instanceId, 'force', (response) ->
          if response == 200
            obj.getLabileData $scope, instanceId, options
          else
            toastr.error _("Failed to delete sesrver: #{instance.name}")

    $scope.search = (key, value) ->
      pageSize = obj.pagingOptions.pageSize
      if value == undefined or value == ''
        if $scope.searched
          $scope.fresh()
          $scope.searched = false
          return
        else
          return
      currentPage = 0
      dataQueryOpts =
        dataFrom: parseInt(pageSize) * parseInt(currentPage)
        dataTo: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize)
        search: true
        searchKey: 'name'
        searchValue: value
        require_detail: true
        tenant_id: $UNICORN.person.project.id
      if obj.additionQueryOpts
        for key, value of obj.additionQueryOpts
          dataQueryOpts[key] = value
      obj.listData $scope, options, dataQueryOpts,
      (items, total) ->
        $scope.searched = true
        obj.setPagingData items, total, $scope, options


  judgeAction: (action, selectedItems) ->
    # Judge the action button is could click
    restirct = {
      batch: true
      status: null
      resource: null
      attr: null
    }

    for key, value of action.restrict
      restirct[key] = value
    if selectedItems.length == 0
      action.enable = false
      return
    else if selectedItems.length == 1
      if !restirct.status
        action.enable = true
      else
        if restirct.status == selectedItems[0].STATUS
          action.enable = true
        else
          action.enable = false
    else
      if restirct.batch == false
        action.enable = false
        return
      else
        action.enable = true
      if restirct.status
        matchedItems = 0
        for item in selectedItems
          if restirct.status == item.STATUS
            matchedItems += 1
        if matchedItems == selectedItems.length
          action.enable = true
        else
          action.enable = false

  itemChange: (newVal, oldVal, $scope, options) ->
    obj = options.$this
    if newVal != oldVal
      selectedItems = []
      matched = false
      for instance in newVal
        # Initiate checking of intermediate state
        if instance.STATUS
          if instance.STATUS in obj.labileStatus\
          or instance.task_state and instance.task_state != 'null'
            obj.getLabileData $scope, instance.id, options
        if $scope.selectedItemId
          if instance.id == $scope.selectedItemId
            instance.isSelected = true
            $scope.selectedItemId = undefined
        if $scope.selectedItem
          if instance.id == $scope.selectedItem
            instance.isSelected = true
            $scope.selectedItem = undefined
            matched = true
          else
            instance.isSelected = false
        if instance.isSelected == true
          selectedItems.push instance
      if !matched
        if newVal.length > 0 and $scope.selectedItem
          $scope.items.push $scope.selectedItem
          $scope.selectedItem = undefined
      $scope.selectedItems = selectedItems

      for action in $scope.actionButtons.buttons
        if !action.restrict
          continue
        obj.judgeAction(action, selectedItems)



class InstanceTable extends $unicorn.TableView
  abnormalStatus: [
    'ERROR'
  ]
  shutdowStatus: [
    'PAUSED'
    'SUSPENDED'
    'STOPPED'
    'SHUTOFF'
  ]
  labileStatus: [
    'deleting'
    'BUILD'
    'REBOOT'
    'MIGRATING'
    'HARD_REBOOT'
    'powering-on'
    'powering-off'
    'image_pending_upload'
  ]
  sortOpts: {
    sortingOrder: 'created'
    reverse: true
  }

  listData: ($scope, options, query, callback) ->
    $http = options.$http
    $window = options.$window
    $q = options.$q
    query['status'] = ['DELETED', 'SOFT_DELETED']
    query['reverse_match_items'] = "['status']"
    $unicorn.listDetailedServers($http, $window, $q, query, callback)
  slug: 'instances'
  labileInstanceQueue: {}

  itemGet: (itemId, options, callback) ->
    $http = options.$http
    $q = options.$q
    $unicorn.serverGet $http, $q, itemId, callback

  getLabileData: ($scope, itemId, options) ->
    obj = options.$this
    # Confirm the task unique for one instance
    if obj.labileInstanceQueue[itemId]
      return
    else
      obj.labileInstanceQueue[itemId] = true

    $interval = options.$interval
    update = () ->
      obj.itemGet itemId, options, (instance) ->
        if instance
          if instance.task_state == null or\
          instance.task_state == 'null'
            $interval.cancel(freshData)
            delete obj.labileInstanceQueue[itemId]
          if instance.STATUS not in obj.labileStatus and\
          instance.task_state == 'null'
            $interval.cancel(freshData)
            delete obj.labileInstanceQueue[itemId]

          for row, index in $scope.items
            if row and row.id == instance.id
              obj.judgeStatus $scope, instance, options
              instance.isSelected = $scope.items[index].isSelected
              $scope.items[index] = instance
              if instance.STATUS == 'DELETED' or\
              instance.STATUS == 'SOFT_DELETED'
                $scope.items.splice(index, 1)

    freshData = $interval(update, obj.REFRESH_ROW_TIMEOUT)
    update()

    if (!$.intervalList)
      $.intervalList = []
    $.intervalList.push(freshData)

  judgeAction: (action, selectedItems) ->
    # Judge the action button is could click
    restirct = {
      batch: true
      status: null
      resource: null
      attr: null
    }
    if (action.name == "attach_volume" \
    or action.name == "detach_volume") \
    and $UNICORN.settings.hypervisor_type.toLocaleLowerCase() == "vmware"
      action.restrict.status = "SHUTOFF"

    for key, value of action.restrict
      restirct[key] = value

    if selectedItems.length == 0
      action.enable = false
      return
    else if selectedItems.length == 1
      if !restirct.status
        action.enable = true
      else
        if restirct.status == selectedItems[0].STATUS
          action.enable = true
        else
          action.enable = false
    else
      if restirct.batch == false
        action.enable = false
        return
      else
        action.enable = true
      if restirct.status
        matchedItems = 0
        for item in selectedItems
          if restirct.status == item.STATUS
            matchedItems += 1
        if matchedItems == selectedItems.length
          action.enable = true
        else
          action.enable = false

    if restirct.resource
      if $UNICORN.settings.hypervisor_type.toLocaleLowerCase() != 'vmware'
        matchedItems = 0
        for item in selectedItems
          if item[restirct.resource]
            if item[restirct.resource].length > 0
              matchedItems += 1
        if matchedItems == selectedItems.length
          action.enable = true
        else
          action.enable = false

    if restirct.attr
      matchedItems = 0
      for item in selectedItems
        if item[restirct.attr]
          matchedItems += 1
      if matchedItems == selectedItems.length
        action.enable = true
      else
        action.enable = false

  itemChange: (newVal, oldVal, $scope, options) ->
    obj = options.$this
    if newVal != oldVal
      selectedItems = []
      matched = false
      for instance in newVal
        # Initiate checking of intermediate state
        if instance.STATUS
          if instance.STATUS in obj.labileStatus\
          or instance.task_state and instance.task_state != 'null'
            obj.getLabileData $scope, instance.id, options
        if $scope.selectedItemId
          if instance.id == $scope.selectedItemId
            instance.isSelected = true
            $scope.selectedItemId = undefined
        if $scope.selectedItem
          if instance.id == $scope.selectedItem
            instance.isSelected = true
            $scope.selectedItem = undefined
            matched = true
          else
            instance.isSelected = false
        if instance.isSelected == true
          selectedItems.push instance
      if !matched
        if newVal.length > 0 and $scope.selectedItem
          $scope.items.push $scope.selectedItem
          $scope.selectedItem = undefined
      $scope.selectedItems = selectedItems

      for action in $scope.actionButtons.buttons
        if !action.restrict
          continue
        obj.judgeAction(action, selectedItems)

      for action in $scope.actionButtons.buttonGroup
        if !action.restrict
          continue
        obj.judgeAction(action, selectedItems)

      # If cloud_desktop not set, we do not need to set desktop button
      cloud_desktop = $UNICORN.settings.cloud_desktop
      if not cloud_desktop
        return false

      setDefault = true
      if selectedItems.length == 1
        setDefault = false
        meta = selectedItems[0].metadata
        ip = selectedItems[0].fixed
        id = selectedItems[0].id
        if $UNICORN.settings.use_neutron
          ip = selectedItems[0].floating
        if ip and ip.length
          ip = ip[0]
          os_type = 'linux'
          try
            meta = JSON.parse meta
            os_type = meta.os_type or 'linux'
          catch e
            console.log "Failed to parse instance metadata"
          $scope.desktop.classes = "btn-enable"
          base = "#{$UNICORN.settings.cloud_desktop}client_add/"
          $scope.desktop.desk_url = "#{base}#{id}/#{ip}"
          if os_type == 'windows'
            $scope.desktop.allow_ssh = false
            $scope.desktop.allow_rdp = true
          else
            $scope.desktop.allow_ssh = true
            $scope.desktop.allow_rdp = true
        else
          setDefault = true
      if setDefault
        $scope.desktop.classes = "btn-disable"
        $scope.desktop.allow_ssh = false
        $scope.desktop.allow_rdp = false
        $scope.desktop.desk_url = "#/dashboard/instance"

  judgeStatus: ($scope, item, options) ->
    obj = options.$this
    if item.status in obj.labileStatus
      item.labileStatus = 'unknwon'
    else if item.status in obj.shutdowStatus
      item.labileStatus = 'stoped'
    else if item.status in obj.abnormalStatus
      item.labileStatus = 'abnormal'
    else
      item.labileStatus = 'active'

    item.STATUS = item.status
    item.status = _(item.status)

    if item.task_state and item.task_state != 'null'
      item.labileStatus = 'unknwon'
      if item.STATUS == 'ACTIVE' or item.STATUS == 'active'
        item.status = _(item.task_state)
      if item.STATUS == 'SHUTOFF' or item.STATUS == 'shutoff'\
      and item.task_state != 'null'
        item.status = _(item.task_state)
      if item.STATUS == 'SUSPENDED' or item.STATUS == 'SUSPENDED'\
      and item.task_state != 'null'
        item.status = _(item.task_state)

  initialAction: ($scope, options) ->
    # Handle message from gossip.
    $scope.$on '$gossipService.instance', (event, meta) ->
      id = meta.payload.id
      $unicorn.serverGet options.$http, options.$q, id, (instance) ->
        if $scope.items
          counter = 0
          len = $scope.items.length
          loop
            break if counter >= len
            if $scope.items[counter].id == id
              break
            counter += 1
          if not instance
            $scope.items.splice counter, 1
            return
          if options.$this.judgeStatus
            options.$this.judgeStatus $scope, instance, options
            $scope.items[counter] = instance

    super $scope, options
    obj = options.$this
    $http = options.$http
    $window = options.$http
    $state = options.$state
    $scope.itemAction = (type, index) ->
      actionName = $scope.actionButtons[type][index].name
      addition = ''
      verbose = $scope.actionButtons[type][index].verbose
      angular.forEach $scope.selectedItems, (instance, index) ->
        instanceId = instance.id
        message =
          object: "instance-#{instanceId}"
          priority: 'info'
          loading: 'true'
          content: _(["Instance %s is %s ...", instance.name, verbose])
        options.$gossipService.receiveMessage message
        $unicorn.instanceAction actionName, $http, $window,
        {'instanceId': instanceId, addition: addition}, (response) ->
          if response
            obj.getLabileData $scope, instanceId, options

    $scope.dataLoading = false
    $scope.applyInstance = () ->
      if $scope.dataLoading
        return
      serverUrl = $UNICORN.settings.serverURL
      workflowTypesURL = "#{serverUrl}/workflow-request-types?enable=1"
      $http.get workflowTypesURL
        .success (data) ->
          if !$unicorn.wfTypesMap
            $unicorn.wfTypesMap = {}
          for wfType in data
            $unicorn.wfTypesMap[String(wfType.id)] = wfType.name
            if wfType.name == 'create_instance'
              instanceReq = String(wfType.id)
          if instanceReq
            $scope.dataLoading = true
            options.$dataLoader($scope, instanceReq, 'modal')
        .error (err) ->
          toastr.error _("Error at load apply types.")

    $scope.tryApply = () ->
      options['type'] = 'instances'
      options['service'] = 'nova'
      options['callback'] = $scope.applyInstance
      options['projectId'] = $UNICORN.person.project.id
      options['serverUrl'] = $UNICORN.settings.serverURL
      options.$tryApply options

    $scope.itemLinkAction = (link, enable) ->
      if not enable
        return false
      if $scope.selectedItems.length != 1
        return
      $state.go link, {instId: $scope.selectedItems[0].id}

    $scope.search = (key, value) ->
      pageSize = obj.pagingOptions.pageSize
      if value == undefined or value == ''
        if $scope.searched
          $scope.fresh()
          $scope.searched = false
          return
        else
          return
      currentPage = 0
      dataQueryOpts =
        dataFrom: parseInt(pageSize) * parseInt(currentPage)
        dataTo: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize)
        search: true
        searchKey: 'name'
        searchValue: value
        require_detail: true
        tenant_id: $UNICORN.person.project.id
      if obj.additionQueryOpts
        for key, value of obj.additionQueryOpts
          dataQueryOpts[key] = value
      obj.listData $scope, options, dataQueryOpts,
      (items, total) ->
        $scope.searched = true
        obj.setPagingData items, total, $scope, options

    $scope.extendTime = (link, enable) ->
      if $scope.dataLoading
        return
      serverUrl = $UNICORN.settings.serverURL
      workflowTypesURL = "#{serverUrl}/workflow-request-types"
      $http.get workflowTypesURL
        .success (data) ->
          if !$unicorn.wfTypesMap
            $unicorn.wfTypesMap = {}
          for wfType in data
            $unicorn.wfTypesMap[String(wfType.id)] = wfType.name
            if wfType.name == 'instance_due_time_extend'
              extendReq = String(wfType.id)
          if extendReq
            $scope.dataLoading = true
            options.$dataLoader($scope, extendReq, 'modal')
        .error (err) ->
          toastr.error _("Error at load apply types.")

    $scope.itemDelete = () ->
      angular.forEach $scope.selectedItems, (instance, index) ->
        instanceId = instance.id
        message =
          object: "instance-#{instanceId}"
          priority: 'info'
          loading: 'true'
          content: _(["Instance %s is %s ...", instance.name, _("deleting")])
        options.$gossipService.receiveMessage message
        $unicorn.serverDelete $http, $window, instanceId, '', (response) ->
          if response == 200
            obj.getLabileData $scope, instanceId, options
          else
            toastr.error _("Failed to delete sesrver: #{instance.name}")

    $scope.filter = (key, value) ->
      pageSize = obj.pagingOptions.pageSize
      if value != 'all'
        obj.additionQueryOpts[key] = value
      else
        delete obj.additionQueryOpts[key]
      currentPage = 0
      dataQueryOpts =
        tenant_id: $UNICORN.person.project.id
        dataFrom: parseInt(pageSize) * parseInt(currentPage)
        dataTo: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize)
      if obj.additionQueryOpts
        for key, value of obj.additionQueryOpts
          dataQueryOpts[key] = value
      obj.listData $scope, options, dataQueryOpts,
      (items, total) ->
        $scope.filtered = true
        obj.setPagingData items, total, $scope, options
