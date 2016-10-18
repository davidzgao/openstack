'use strict'

###*
 # @ngdoc function
 # @name Cross.project.instance
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.project.instance')
  .controller 'project.instance.instancesCtrl', ($scope, $http, $gossipService
  $window, $q, $state, $interval, $selectedItem, $running, $deleted, $instanceSetUp, $rootScope) ->
    $rootScope.$on 'instance.floatingIp', (event, meta) ->
      update = () ->
        $cross.serverGet $http, $window, $q, meta[0], (instance) ->
          if instance.floating.length != meta[1]
            angular.forEach $scope.instancesOpts.data, (row, index) ->
              if row.id == instance.id
                row.floating = instance.floating
                $interval.cancel(freshData)
      freshData = $interval(update, 3000)
      update()
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

    serverUrl = $window.$CROSS.settings.serverURL
    # Category for instance action
    $scope.singleSelectedItem = {}
    $scope.canMantance = 'disabled'
    $scope.canBackup = 'disabled'
    $scope.canBind = 'disabled'
    $scope.canUnbind = 'disabled'
    $scope.canAttachOrDetach = 'disabled'

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

    $scope.statusJudge = (able, id, url) ->
      if able == 'disabled'
        $state.go "project.instance"
      else
        $state.go url, {instId:id}

    $scope.mantanceActions = [
      {
        action: 'snapshot'
        verbose: _('Snapshot')
        enable: 'disabled'
        actionTemplate: '<a ng-init=\'url = "project.instance.instId.snapshot"\' ng-click="statusJudge(canBackup, singleSelectedItem.id, url)" ng-class="canBackup" enabled-status="{{canBackup}}"><i ng-class="action.action"></i>{{action.verbose}}</a>'
      }
      {
        action: 'resize'
        verbose: _('Resize')
        enable: 'disabled'
        actionTemplate: '<a ng-init=\'url = "project.instance.instId.resize"\' ng-click="statusJudge(canMantance, singleSelectedItem.id, url)" ng-class="canMantance" enabled-status="{{canMantance}}"><i ng-class="action.action"></i>{{action.verbose}}</a>'
      }
    ]

    # NOTE(ZhengYue): network/volume actions not need for admin
    $scope.networkActions = [
      {
        action: 'bindIp'
        verbose: _('Bind IP')
        enable: 'disabled'
        actionTemplate: '<a ng-init=\'url = "project.instance.instId.bindIp"\' ng-click="statusJudge(canBind, singleSelectedItem.id, url)" ng-class="canBind" enabled-status="{{canBind}}"><i ng-class="action.action"></i>{{action.verbose}}</a>'
      }
      {
        action: 'unbindIp'
        verbose: _('Unbind IP')
        enable: 'disabled'
        actionTemplate: '<a ng-init=\'url = "project.instance.instId.unbindIp"\' ng-click="statusJudge(canUnbind, singleSelectedItem.id, url)" ng-class="canUnbind" enabled-status="{{canUnbind}}"><i ng-class="action.action"></i>{{action.verbose}}</a>'
      }
    ]
    $scope.volumeActions = [
      {
        action: 'attachVolume'
        verbose: _('Attach Volume')
        enable: 'disabled'
        actionTemplate: '<a ng-init=\'url = "project.instance.instId.attachVolume"\' ng-click="statusJudge(canAttachOrDetach, singleSelectedItem.id, url)" ng-class="canAttachOrDetach" enabled-status="{{canAttachOrDetach}}"><i ng-class="action.action"></i>{{action.verbose}}</a>'
      }
      {
        action: 'detachVolume'
        verbose: _('Detach Volume')
        enable: 'disabled'
        actionTemplate: '<a ng-init=\'url = "project.instance.instId.detachVolume"\' ng-click="statusJudge(canAttachOrDetach, singleSelectedItem.id, url)" ng-class="canAttachOrDetach" enabled-status="{{canAttachOrDetach}}"><i ng-class="action.action"></i>{{action.verbose}}</a>'
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
    $scope.filterOptions =
      filterText: '',
      useExternalFilter: true

    $scope.instances = [
    ]

    $scope.instancesOpts = {
      pagingOptions: $scope.pagingOptions
      showCheckbox: true
      columnDefs: $scope.columnDefs
      pageMax: 5
    }

    # Functions for handle event from action

    $scope.selectedItems = []

    # Functions about interaction with server
    # --Start--

    $scope.labileInstanceQueue = {}

    # Function for async list instances
    $scope.getPagedDataAsync = (pageSize, currentPage, callback) ->
      setTimeout(() ->
        currentPage = currentPage - 1
        dataQueryOpts =
          dataFrom: parseInt(pageSize) * parseInt(currentPage)
          dataTo: parseInt(pageSize) * parseInt(currentPage) + parseInt(pageSize)
          status: ['DELETED', 'SOFT_DELETED']
          reverse_match_items: "['status']"
        $cross.listDetailedServers $http, $window, $q, dataQueryOpts,
        (instances, total) ->
          $scope.setPagingData(instances, total)
          (callback && typeof(callback) == "function") && callback()
      , 300)

    $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                             $scope.pagingOptions.currentPage)

    # Callback for instance list after paging change
    watchCallback = (newVal, oldVal) ->
      $scope.instancesOpts.data = null
      if newVal != oldVal and newVal.currentPage != oldVal.currentPage
        $scope.getPagedDataAsync $scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage

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
        $scope.canBind = 'disabled'
        $scope.canUnbind = 'disabled'
        $scope.canAttachOrDetach = 'disabled'
      else
        if $scope.selectedItems.length == 1
          instance = $scope.selectedItems[0]
          if instance.labileStatus == 'unknwon'\
          or instance.labileStatus == 'abnormal'
            angular.forEach $scope.batchActions, (action, index) ->
              action.enable = 'disabled'
            $scope.canMantance = 'disabled'
            $scope.canBackup = 'disabled'
            $scope.canBind = 'disabled'
            $scope.canUnbind = 'disabled'
            $scope.canAttachOrDetach = 'disabled'
          else if instance.labileStatus == 'stoped'
            $scope.canMantance = 'disabled'
            $scope.canBackup = 'enabled'
            if instance.STATUS == 'SHUTOFF'
              $scope.canAttachOrDetach = \
              if $CROSS.settings.hypervisor_type.toLocaleLowerCase() ==\
              "vmware" then 'enabled' else 'disabled'
              $scope.batchActions[1].enable = 'enabled'
              $scope.mantanceActions[1].enable = 'enabled'
            if instance.STATUS == 'SUSPENDED'
              $scope.batchActions[4].enable = 'enabled'
            $scope.batchActions[0].enable = 'enabled'
          else if instance.labileStatus == 'active'
            if instance.STATUS == 'ACTIVE'
              $scope.batchActions[2].enable = 'enabled'
              $scope.batchActions[3].enable = 'enabled'
            $scope.batchActions[0].enable = 'enabled'
            $scope.canMantance = 'enabled'
            $scope.canBackup = 'enabled'
            $scope.canBind = 'enabled'
            $scope.canUnbind = 'enabled'
            $scope.canAttachOrDetach = \
            if $CROSS.settings.hypervisor_type\
            and $CROSS.settings.hypervisor_type.toLocaleLowerCase() ==\
            "vmware" then 'disabled' else 'enabled'
        else
          $scope.canMantance = 'disabled'
          $scope.canBackup = 'disabled'
          $scope.canBind = 'disabled'
          $scope.canUnbind = 'disabled'
          $scope.canAttachOrDetach = 'disabled'
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
          if listInShutoff.length == $scope.selectedItems.length
            $scope.batchActions[0].enable = 'enabled'
            $scope.batchActions[1].enable = 'enabled'
          if listInSuspend.length == $scope.selectedItems.length
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
        instanceId = item.id
        message =
          object: "instance-#{instanceId}"
          priority: 'success'
          loading: 'true'
          content: _(["Instance %s is %s ...", item.name, _("deleting")])
        $gossipService.receiveMessage message
        $cross.serverDelete $http, $window, instanceId, undefined, (response) ->
          if response == 200
            angular.forEach $scope.instances, (row, index) ->
              if row.id == instanceId
                $scope.instances[index].pureStatus = 'deleting'
                $scope.instances[index].status = 'deleting'
                $scope.judgeStatus $scope.instances[index]
                return false
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
          # TODO(ZhengYue): Add some tips for success or failed
          # If success update instance predic
          if response
            $scope.getLabileData(instanceId, actionName)

    # --End--

    $scope.refresResource = (resource) ->
      $scope.instancesOpts.data = null
      $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                               $scope.pagingOptions.currentPage)
    $selectedItem $scope, 'instances'
