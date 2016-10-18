'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.admin.instance')
  .controller 'admin.instance.instancesCtrl', ($scope, $http, $window, $instanceSetUp,
  $q, $state, $interval, $selectedItem, $running, $deleted, $gossipService) ->
    serverUrl = $window.$CROSS.settings.serverURL
    $scope.$on '$gossipService.instance', (event, meta) ->
      id = meta.payload.id
      $cross.serverGet $http, $window, $q, id, (instance) ->
        if $scope.instances
          counter = 0
          len = $scope.instances.length
          loop
            break if counter >= len
            if $scope.instances[counter].id == id
              break
            counter += 1
          if not instance
            $scope.instances.splice counter, 1
            return
          if $scope.judgeStatus
            $scope.judgeStatus instance
            $scope.instances[counter] = instance

    # Category for instance action
    $scope.singleSelectedItem = {}
    $scope.canMantance = 'disabled'
    $scope.canBackup = 'disabled'

    $instanceSetUp $scope, $interval, $running

    $scope.batchActions = [
      {
        action: 'reboot',
        verbose: _('Reboot'),
        enable: 'disabled',
        addition:
          message: _('Hard Reboot')
          default: false
          choicees: ['SOFT', 'HARD']
      }
      {action: 'poweron', verbose: _('Power On'), enable: 'disabled'}
      {action: 'poweroff', verbose: _('Power Off'), enable: 'disabled'}
      {action: 'suspend', verbose: _('Suspend'), enable: 'disabled'}
      {action: 'wakeup', verbose: _('Wakeup'), enable: 'disabled'}
    ]

    $scope.mantanceActions = [
      {
        action: 'snapshot'
        verbose: _('Snapshot')
        enable: 'disabled'
        actionTemplate: '<a ui-sref="admin.instance.instId.snapshot({ instId: singleSelectedItem.id })" ng-class="canBackup" enabled-status="{{canBackup}}" id="instance-snapshot"><i ng-class="action.action"></i>{{action.verbose}}</a>'
      }
      {
        action: 'migrate'
        verbose: _('Migrate')
        enable: 'disabled'
        actionTemplate: '<a ui-sref="admin.instance.instId.migrate({ instId: singleSelectedItem.id})" ng-class="canMantance" enabled-status="{{canMantance}}" id="instance-migrate"><i ng-class="action.action"></i>{{action.verbose}}</a>'
      }
    ]

    # Variates for dataTable
    # --start--

    # For checkbox select
    $scope.AllSelectedItems = false
    $scope.NoSelectedItems = true

    # For tabler footer and pagination or filter
    $scope.showFooter = true
    $scope.unFristPage = false
    $scope.unLastPage = false

    $scope.totalServerItems = 0
    $scope.pagingOptions = {
      pageSizes: [15, 25, 50]
      pageSize: 15
      currentPage: 1
    }

    $scope.instances = [
    ]

    $scope.instancesOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      pageMax: 5
      sort: $scope.sort
      slug: _ "Instances"
    }

    $scope.searchKey = 'name'
    $scope.search = (key, value) ->
      pageSize = $scope.pagingOptions.pageSize
      if value == undefined or value == ''
        if $scope.searched
          $scope.pagingOptions.currentPage = 1
          $scope.refresResource()
          $scope.searched = false
          return
        else
          return
      if $scope.noSearchMatch
        if $scope.oldSearchValue
          if value.length > $scope.oldSearchValue.length
            return
      $scope.oldSearchValue = value
      $scope.pagingOptions.currentPage = 1
      currentPage = 1
      $scope.searched = true
      $scope.getPagedDataAsync pageSize, currentPage, (instances) ->
        if instances.length == 0
          $scope.noSearchMatch = true
        else
          $scope.noSearchMatch = false

    $scope.searchOpts = {
      search: () ->
        $scope.search($scope.searchKey, $scope.searchOpts.val)
      showSearch: true
    }

    $scope.filter = (key, value) ->
      pageSize = $scope.pagingOptions.pageSize
      additionQueryOpts = {}
      if value != 'all'
        additionQueryOpts[key] = value
      else
        delete additionQueryOpts[key]
      $scope.pagingOptions.currentPage = 1
      currentPage = 0
      dataQueryOpts =
        dataFrom: parseInt(pageSize) * parseInt(currentPage)
        dataTo: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize)
        all_tenants: true
      if additionQueryOpts
        for key, value of additionQueryOpts
          dataQueryOpts[key] = value
      $scope.filterOpts = dataQueryOpts
      $cross.listDetailedServers $http, $window, $q, dataQueryOpts,
      (instances, total) ->
        $scope.filtered = true
        $scope.setPagingData(instances, total)

    $scope.instancesOpts.filterAction = (key, values) ->
      for value in values
        if value.selected == true
          $scope.filter(key, value.value)
          break

    # Functions for handle event from action

    $scope.selectedItems = []

    getElement = $interval(() ->
      snapshotLink = angular.element("#instance-snapshot")
      migrateLink = angular.element("#instance-migrate")
      snapshotLink.bind 'click', ->
        return false
      migrateLink.bind 'click', ->
        return false
      if snapshotLink.length and migrateLink.length
        $interval.cancel(getElement)
    , 300)

    $scope.$watch 'singleSelectedItem', (newVal, oldVal) ->
      snapshotLink = angular.element("#instance-snapshot")
      migrateLink = angular.element("#instance-migrate")
      if newVal != oldVal
        # FIXME(liuhaobo): As snapshot condition is not only
        # ACTIVE/SHUTOFF for instances, I think this need an
        # confirm.
        if newVal.STATUS == 'ACTIVE'
          snapshotLink.unbind 'click'
          migrateLink.unbind 'click'
        else if newVal.STATUS == 'SHUTOFF'
          snapshotLink.unbind 'click'
          migrateLink.bind 'click', ->
            return false
        else
          snapshotLink.bind 'click', ->
            return false
          migrateLink.bind 'click', ->
            return false
    , true

    # Functions about interaction with server
    # --Start--

    $scope.labileInstanceQueue = {}
    # Function for async list instances

    $scope.getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        $scope.listServers = true
        currentPage = currentPage - 1
        dataQueryOpts =
          all_tenants: true
          dataFrom: parseInt(pageSize) * parseInt(currentPage)
          dataTo: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize)
          status: 'SOFT_DELETED'
          reverse_match_items: "['status']"
        if $scope.searched
          dataQueryOpts.search = true
          dataQueryOpts.searchKey = $scope.searchKey
          dataQueryOpts.searchValue = $scope.searchOpts.val
          dataQueryOpts.require_detail = true
        else if $scope.filtered
          dataQueryOpts.status = $scope.filterOpts.status
        $cross.listDetailedServers $http, $window, $q, dataQueryOpts,
        (instances, total) ->
          $scope.setPagingData(instances, total)
          (callback && typeof(callback) == "function") &&\
          callback(instances)
      , 300)

    $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    # Callback for instance list after paging change
    watchCallback = (newVal, oldVal) ->
      $scope.instancesOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage,

    $scope.$watch('pagingOptions', watchCallback, true)

    # Enable/disable some action for selected instance
    # by instance status
    $scope.checkActionPermission = () ->
      $scope.resetStatus()
      if $scope.selectedItems.length == 0
        angular.forEach $scope.batchActions, (action, index) ->
          action.enable = 'disabled'
        $scope.canMantance = 'disabled'
        $scope.canBackup = 'disabled'
      else
        if $scope.selectedItems.length == 1
          instance = $scope.selectedItems[0]
          if instance.labileStatus == 'unknwon'\
          or instance.labileStatus == 'abnormal'
            angular.forEach $scope.batchActions, (action, index) ->
              action.enable = 'disabled'
            $scope.canMantance = 'disabled'
            $scope.canBackup = 'disabled'
          else if instance.labileStatus == 'stoped'
            if instance.STATUS == 'SHUTOFF'
              $scope.batchActions[1].enable = 'enabled'
            if instance.STATUS == 'SUSPENDED'
              $scope.batchActions[4].enable = 'enabled'
            $scope.batchActions[0].enable = 'enabled'
            $scope.canMantance = 'disabled'
            $scope.canBackup = 'enabled'
          else if instance.labileStatus == 'active'
            if instance.STATUS == 'ACTIVE'
              $scope.batchActions[2].enable = 'enabled'
              $scope.batchActions[3].enable = 'enabled'
            $scope.batchActions[0].enable = 'enabled'
            $scope.canMantance = 'enabled'
            $scope.canBackup = 'enabled'
        else
          $scope.canMantance = 'disabled'
          $scope.canBackup = 'disabled'
          listInActive = []
          listInShutoff = []
          listInSuspend = []
          angular.forEach $scope.selectedItems, (instance, index) ->
            if instance.STATUS == 'ACTIVE'
              listInActive.push instance
            else if instance.STATUS == 'SUSPENDED'
              listInSuspend.push instance
            else if instance.STATUS == 'SHUTOFF'
              listInShutoff.push instance

          if listInActive.length == $scope.selectedItems.length
            $scope.batchActions[0].enable = 'enabled'
            $scope.batchActions[2].enable = 'enabled'
            $scope.batchActions[3].enable = 'enabled'
          else if listInShutoff.length == $scope.selectedItems.length
            $scope.batchActions[0].enable = 'enabled'
            $scope.batchActions[1].enable = 'enabled'
          else if listInSuspend.length == $scope.selectedItems.length
            $scope.batchActions[0].enable = 'enabled'
            $scope.batchActions[4].enable = 'enabled'

    # Callback after instance list change
    instanceCallback = (newVal, oldVal) ->
      if newVal != oldVal
        selectedItems = []
        for instance in newVal
          if $scope.selectedItemId
            if instance.id == $scope.selectedItemId
              instance.isSelected = true
              $scope.selectedItemId = undefined
          if instance.STATUS in $scope.labileStatus\
          or instance.task_state and instance.task_state != 'null'
            $scope.getLabileData(instance.id)
          if instance.isSelected == true
            selectedItems.push instance
        $scope.selectedItems = selectedItems
        $scope.checkActionPermission()

    $scope.$watch('instances', instanceCallback, true)

    $scope.$watch('selectedItems', $scope.selectChange, true)

    # Delete selected servers
    $scope.deleteServer = () ->
      angular.forEach $scope.selectedItems, (item, index) ->
        if item.STATUS == "ERROR"
          data = {
            "os-resetState": {
              "state": "active"
            }
          }
          data = JSON.stringify(data)
          $http.post "#{serverUrl}/servers/#{item.id}/action", data
            .success ->
              instanceId = item.id
              message =
                object: "instance-#{instanceId}"
                priority: 'info'
                loading: 'true'
                content: _(["Instance %s is %s ...", item.name, _("deleting")])
              $gossipService.receiveMessage message
              $cross.serverDelete $http, $window, instanceId, '', (response) ->
                if response == 204 or response == 200
                  $scope.getLabileData(instanceId, 'delete')
            .error (err) ->
              toastr.error _(["Failed to delete instance %s", item.name])
        else
          instanceId = item.id
          message =
            object: "instance-#{instanceId}"
            priority: 'info'
            loading: 'true'
            content: _(["Instance %s is %s ...", item.name, _("deleting")])
          $gossipService.receiveMessage message
          $cross.serverDelete $http, $window, instanceId, '', (response) ->
            if response == 200
              $scope.getLabileData(instanceId, 'delete')

    $scope.serverAction = (action, group, addition) ->
      actionName = $scope["#{group}Actions"][action].action
      if addition
        $scope.resetActionDefult()
      verbose = $scope["#{group}Actions"][action].verbose
      angular.forEach $scope.selectedItems, (item, index) ->
        instanceId = item.id
        message =
          object: "instance-#{instanceId}"
          priority: 'info'
          loading: 'true'
          content: _(["Instance %s is %s ...", item.name, verbose])
        $gossipService.receiveMessage message
        $cross.instanceAction actionName, $http, $window,
        {'instanceId': instanceId, addition: addition}, (response) ->
          if response
            $scope.getLabileData(instanceId, actionName)

    # --End--

    $scope.refresResource = (resource) ->
      $scope.instancesOpts.data = null
      $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                               $scope.pagingOptions.currentPage)

    # NOTE: (ZhengYue): Listening the event which sended after
    # action success from rootScope. The detail in pararms at callback
    # is the correlated resrource ID. If the event occurred, trigger
    # request and update DOM.
    $scope.$on('actionSuccess', (event, detail) ->
      if detail.type == 'instance'
        $scope.getLabileData(detail.id)
    )

    $selectedItem $scope, 'instances'
