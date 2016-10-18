'use strict'

###
 # @description
 # # The services module of Cross
 #
 # loginCheck service is used for user is login or not
 #
 # stringToDatetime service is used for transform string value
 # to dateTime value
 # # for example:
 # ##  "2012-12-20 23:59:59"
 # ##  "2012.12.20 23:59:59"
 # ##  "2012/12/20 23:59:59"
 # ##  "2012\12\20 23:59:59"
 # # Those string can all transform to dateTime.
 #
 # getAttachVolFromServer service is used for get attached
 # volumes infomations form server.
 # # volumes infomations as follow:
 # ##  display_name@string
 # ##  id@string
 # ##  size@string
 # ##  bootable@string
 #
 # getCinderQuota service is used for get cinder quota infos.
 #
 #
###

angular.module('Cross.services', [])
  .factory 'randomName', () ->
    return (num) ->
      chars = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0',\
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',\
      'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x',\
      'y', 'z']
      res = ''

      for n in [1..num]
        id = Math.ceil(Math.random()*35)
        res += chars[id]

      return res
  .factory 'getAttachVolFromServer', ['$http', '$q', ($http, $q) ->
    (server, $scope) ->
      $scope.volumes = []
      $scope.form['snapshot_object'] = []
      # NOTE(liuhaobo): Make a fake system volume
      # to bound HTML model.
      # Because the instance which boot from image has
      # no system volume.
      fakeSysVol =
        display_name: _ "System Volume"
        size: 0
        selected: true
        bootable: 'true'
      $scope.volumes.push fakeSysVol if server.image
      $scope.form['snapshot_object'].push fakeSysVol if server.image
      serverUrl = $CROSS.settings.serverURL
      volumeIdList = server['os-extended-volumes:volumes_attached']
      volumeIdList = JSON.parse volumeIdList
      httpRequest = []
      for n in [0..(volumeIdList.length - 1)]
        httpRequest.push($http.get "#{serverUrl}/volumes/#{volumeIdList[n].id}") if volumeIdList[n]
      $q.all(httpRequest)
        .then (values) ->
          for value in values
            volume = value.data
            volume.display_name = volume.display_name or volume.id
            if volume.bootable == 'true'
              volName = _("System Volume") + ':' + volume.display_name
            else
              volName = _("Data Volume") + ':' + volume.display_name
            volItem =
              display_name: volName
              id: volume.id
              size: volume.size
              selected: true
              bootable: volume.bootable
            $scope.volumes.push angular.copy(volItem)
            $scope.form['snapshot_object'].push angular.copy(volItem)
        .catch (err) ->
          console.error "Failed to get volumes info: #{err}"
      return
  ]
  .factory 'getCinderQuota', ['$http', ($http) ->
    (callback) ->
      serverUrl = $CROSS.settings.serverURL
      projectId = $CROSS.person.project.id
      $http.get "#{serverUrl}/cinder/os-quota-sets/#{projectId}?usage=true"
        .success (quota) ->
          callback quota
        .error (err) ->
          console.error "Meet error when get cinder quota:", err
  ]
  .factory 'floatingIPRefresh', ['$http', '$interval', '$rootScope', ($http, $interval, $rootScope) ->
    return (floatingIpMeta, bindFlag, instanceId) ->
      update = () ->
        serverUrl = $CROSS.settings.serverURL
        floatingIpNum = floatingIpMeta.floatingIpNum
        if bindFlag
          floatingIpId = floatingIpMeta.floatingIpId
          $http.get("#{serverUrl}/os-floating-ips/#{floatingIpId}")
            .success (net) ->
              if net.instance_id
                options = [net.instance_id, floatingIpNum]
                $rootScope.$broadcast 'instance.floatingIp', options
                $interval.cancel(freshdata)
        else
          $http.get "#{serverUrl}/servers/#{instanceId}"
            .success (server) ->
              fIps = []
              addrs = JSON.parse server.addresses
              for pool of addrs
                for add in addrs[pool]
                  if add['OS-EXT-IPS:type'] == 'floating'
                    fIps.push add['addr']
              if not fIps.length
                fIps.push null
              if floatingIpMeta.floatingIpAddr not in fIps
                options = [instanceId, floatingIpNum]
                $rootScope.$broadcast 'instance.floatingIp', options
                $interval.cancel(freshdata)

      freshdata = $interval(update, 3000)
      update()
  ]

  .factory 'stringToDatetime', () ->
    return (str) ->
      if typeof str!="string"
        return null
      strInfo = str.match(/^(\d{1,4})(-|\/|[]|[.])(\d{1,2})\2(\d{1,2})[ ](\d{1,2}):(\d{1,2}):(\d{1,2})$/)
      dateTime = new Date()
      if strInfo == null
        return null
      year = parseInt(strInfo[1], 10)
      month = parseInt(strInfo[3], 10)
      day = parseInt(strInfo[4], 10)
      hour = parseInt(strInfo[5], 10)
      minute = parseInt(strInfo[6], 10)
      second = parseInt(strInfo[7], 10)
      if month > 12 or month < 0 \
      or day > 31 or day < 0 \
      or hour > 23 or hour < 0 \
      or minute > 59 or minute < 0 \
      or second > 59 or second < 0
        return null
      dateTime.setFullYear(year)
      dateTime.setMonth(month - 1)
      dateTime.setDate(day)
      dateTime.setHours(hour)
      dateTime.setMinutes(minute)
      dateTime.setSeconds(second)
      dateTime.setUTCHours(30)
      dateTime = dateTime.toISOString()
      dateTime = dateTime.substr(0, 23)
      return dateTime

  .factory '$logincheck', ['$location', '$q', '$injector',
  '$window', '$rootScope', ($location, $q, $injector, $window,
  $rootScope) ->
    return {
      responseError: (response) ->
        # Sign out if the user is no longer authorized.
        if response.status == 401 or (response.data and response.data.status == 401)
          hash = location.hash
          if $rootScope.unautherized
            if hash == '#/login'
              return $q.reject(response)
            return
          $rootScope.unautherized = true
          if hash != '#/login' and hash != '#/forgetpassword'
            currentPath = $location.$$path
            $location.path("/login").search({next: currentPath})
            toastr.warning _("Session timeout, please login again")
            return

        if response.status == 0
          err_data = {"error_description": "Could not connect to the server"}
          response.data = err_data

        return $q.reject(response)
    }
  ]
  .factory '$tabs', ['$state', '$stateParams', ($state, $stateParams) ->
    return ($scope, baseURL) ->
      if $stateParams.tab
        for tab in $scope.tabs
          if tab.slug == $stateParams.tab
            $scope.currentTab = tab.template
            break
      else
        $scope.currentTab = $scope.tabs[0]['template']
      $scope.onClickTab = (tab) ->
        if baseURL
          $state.go baseURL, {tab: tab.slug}, {inherit: false}
        $scope.currentTab = tab.template
      $scope.isActiveTab = (tabUrl) ->
        return tabUrl == $scope.currentTab
    ]
  .factory '$selected', () ->
    return ($scope) ->
      $scope.$emit('selected', $scope.currentId)

  .factory '$selectedItem', () ->
    return ($scope, items) ->
      $scope.$on 'selected', (event, detail) ->
        if $scope[items].length > 0
          for item in $scope[items]
            itemId = String(item.id)
            if itemId == detail
              item.isSelected = true
            else
              item.isSelected = false
        else
          $scope.selectedItemId = detail
  .factory '$running', () ->
    return ($scope, itemId) ->
      $scope.$broadcast('running', itemId)
  .factory '$updateDetail', () ->
    return ($scope) ->
      $scope.$on 'running', (event, detail) ->
        if detail == $scope.currentId
          $scope.update()
  .factory '$deleted', () ->
    return ($scope, itemId) ->
      $scope.$broadcast('deleted', itemId)
  .factory '$watchDeleted', () ->
    return ($scope, $state) ->
      $scope.$on 'deleted', (event, detail) ->
        if detail == $scope.currentId
          $state.go '^'
  .factory '$clearInterval', () ->
    return ($scope, $interval) ->
      $scope.$on('$destroy', () ->
      if $.intervalList
        angular.forEach $.intervalList, (task, index) ->
          $interval.cancel task
    )
  .factory '$projectSetUp', () ->
    return ($scope) ->
      $scope.$watch 'all_user', (newVal, oldVal) ->
        if newVal != oldVal
          if newVal.length == 0
            $scope.no_available = true
          else
            $scope.no_available = false
      , true

      $scope.$watch "userList", (newVal, oldVal) ->
        if newVal != oldVal
          if newVal.length == 0
            $scope.no_selected = true
          else
            $scope.no_selected = false
      , true

      $scope.addToLeft = (userId) ->
        clickedUser = {}
        angular.forEach $scope.all_user, (user, index) ->
          if userId == user.value
            clickedUser = user
            $scope.all_user.splice(index, 1)
            if $scope.modal.single
              $scope.modal.fields[1].default.push clickedUser
            else
              $scope.userList.push clickedUser
            return

      $scope.addToRight = (userId) ->
        clickedUser = {}
        if $scope.modal.single
          angular.forEach $scope.modal.fields[1].default, (user, index) ->
            if userId == user.value
              clickedUser = user
              $scope.modal.fields[1].default.splice(index, 1)
              $scope.all_user.push clickedUser
              return
        else
          angular.forEach $scope.userList, (user, index) ->
            if userId == user.value
              clickedUser = user
              $scope.userList.splice(index, 1)
              $scope.all_user.push clickedUser
              return


      escapeRegExp = (str) ->
        return str.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")

      $scope.search = {}
      $scope.searchAllUser = (name) ->
        if !$scope.search.all
          return true
        regex = new RegExp('\\b' + escapeRegExp($scope.search.all), 'i')
        return regex.test(name.text)

      $scope.searchMembers = (name) ->
        if !$scope.search.member
          return true
        regex = new RegExp('\\b' + escapeRegExp($scope.search.member), 'i')
        return regex.test(name.text)
  .factory '$instanceSetUp', ['$http', '$window', '$q', '$deleted',
  ($http, $window, $q, $deleted) ->
    return ($scope, $interval, $running) ->
      $scope.resetStatus = () ->
        for action in $scope.batchActions
          action.enable = 'disabled'

      $scope.resetActionDefult = () ->
        angular.forEach $scope.batchActions, (action, index) ->
          if action.action == 'reboot'
            action.addition.default = false

      $scope.judgeStatus = (item) ->
        if item.status in $scope.labileStatus
          item.labileStatus = 'unknwon'
        else if item.status in $scope.shutdowStatus
          item.labileStatus = 'stoped'
        else if item.status in $scope.abnormalStatus
          item.labileStatus = 'abnormal'
        else
          item.labileStatus = 'active'

        item.STATUS = item.status
        item.status = _(item.status)

        if item.task_state and item.task_state != 'null'\
        and item.status not in $scope.abnormalStatus
          item.labileStatus = 'unknwon'
          if item.STATUS == 'ACTIVE' or item.STATUS == 'active'
            item.status = _(item.task_state)
          if item.STATUS == 'SHUTOFF' or item.STATUS == 'shutoff'\
          and item.task_state != 'null'
            item.status = _(item.task_state)
          if item.STATUS == 'SUSPENDED' or item.STATUS == 'suspended'\
          and item.task_state != 'null'
            item.status = _(item.task_state)
          if item.STATUS == 'RESCUE' or item.STATUS == 'rescue'\
          and item.task_state != 'null'
            item.status = _(item.task_state)

      # Function for get paded instances and assign class for
      # element by status
      $scope.setPagingData = (pagedData, total) ->
        $scope.instances = pagedData
        $scope.totalServerItems = total
        # Compute the total pages
        $scope.pageCounts = Math.ceil(total / $scope.pagingOptions.pageSize)
        $scope.instancesOpts.data = $scope.instances
        $scope.instancesOpts.pageCounts = $scope.pageCounts

        for item in pagedData
          $scope.judgeStatus item

        if !$scope.$$phase
          $scope.$apply()

      $scope.selectChange = () ->
        if $scope.selectedItems.length == 1
          $scope.NoSelectedItems = false
          $scope.batchActionEnableClass = 'btn-enable'
          $scope.vncLinkEnableClass = 'btn-enable'
          $scope.singleSelectedItem = $scope.selectedItems[0]
        else if $scope.selectedItems.length > 1
          $scope.NoSelectedItems = false
          $scope.batchActionEnableClass = 'btn-enable'
          $scope.vncLinkEnableClass = 'btn-disable'
          $scope.singleSelectedItem = {}
        else
          $scope.NoSelectedItems = true
          $scope.batchActionEnableClass = 'btn-disable'
          $scope.vncLinkEnableClass = 'btn-disable'
          $scope.singleSelectedItem = {}

      $scope.getLabileData = (instanceId, preambl) ->
        if $scope.labileInstanceQueue[instanceId]
          return
        else
          $running $scope, instanceId
          $scope.labileInstanceQueue[instanceId] = true

        update = () ->
          $cross.serverGet $http, $window, $q, instanceId, (instance) ->
            if instance
              if instance.task_state == null or \
              instance.task_state == 'null' and \
              instance.floating.length == 0
                $interval.cancel(freshData)
                $running $scope, instanceId
                delete $scope.labileInstanceQueue[instanceId]
              if instance.STATUS not in $scope.labileStatus\
              and instance.task_state == 'null'\
              and instance.floating.length == 0
                $interval.cancel(freshData)
                $running $scope, instanceId
                delete $scope.labileInstanceQueue[instanceId]

              angular.forEach $scope.instances, (row, index) ->
                if row.id == instance.id
                  instance.isSelected = $scope.instances[index].isSelected
                  $scope.instances[index] = instance
                  if instance.status == 'DELETED' or\
                  instance.status == 'SOFT_DELETED'
                    $deleted $scope, instance.id
                    $scope.instances.splice(index, 1)
                  if $scope.softDeleted and\
                  instance.status != 'SOFT_DELETED'
                    $deleted $scope, instance.id
                    $scope.instances.splice(index, 1)
                  $scope.judgeStatus instance
            else
              $interval.cancel(freshData)
              $deleted $scope, instanceId
              delete $scope.labileInstanceQueue[instanceId]
              angular.forEach $scope.instances, (row, index) ->
                if row.id == instanceId
                  $scope.instances.splice(index, 1)

        freshData = $interval(update, 5000)
        update()

        if (!$.intervalList)
          $.intervalList = []
        $.intervalList.push(freshData)

      $scope.deleteServer = () ->
        angular.forEach $scope.selectedItems, (item, index) ->
          instanceId = item.id
          $cross.serverDelete $http, $window, instanceId, '', (response) ->
            if response == 200
              $scope.getLabileData(instanceId, 'delete')

      $scope.serverAction = (action, group, addition) ->
        actionName = $scope["#{group}Actions"][action].action
        if addition
          $scope.resetActionDefult()
        angular.forEach $scope.selectedItems, (item, index) ->
          instanceId = item.id
          $cross.instanceAction actionName, $http, $window,
          {'instanceId': instanceId, addition: addition}, (response) ->
            if response
              $scope.getLabileData(instanceId, actionName)

      $scope.refresResource = (resource) ->
        $scope.instancesOpts.data = null
        $scope.getPagedDataAsync($scope.pagingOptions.pageSize,
                                 $scope.pagingOptions.currentPage)

      $scope.$on('actionSuccess', (event, detail) ->
        if detail.type == 'instance'
          $scope.getLabileData(detail.id)
      )

      $scope.$on('$destroy', () ->
        if $.intervalList
          angular.forEach $.intervalList, (task, index) ->
            $interval.cancel task
      )

      $scope.$on('update', (event, detail) ->
        for instance in $scope.instances
          if instance.id == detail.id
            instance.name = detail.name
            break
      )
    ]
  .factory '$updateServer', ['$http', '$window', ($http, $window) ->
    return ($scope, key, value, type) ->
      serverURL = $CROSS.settings.serverURL
      if type != 'metadata'
        body =
          name: value
        $http.put "#{serverURL}/servers/#{$scope.currentId}", body
          .success (data)->
            toastr.success _("Successfully update server: ") + value
            $scope.$emit("update", data)
          .error (error) ->
            toastr.error(_ "Failed to update server: " +
              $scope.server_detail.name)
      else
        body =
          meta:
            "autoBoot": if value == 'Enable' then 'true' else 'false'
        $http.put "#{serverURL}/servers/#{$scope.currentId}/metadata/autoBoot", body
          .success (data) ->
            toastr.success _("Successfully update server auto boot: ") + _ value
            $scope.server_detail.autoBoot = if value == 'Enable' then true else false
          .error (error) ->
            toastr.error(_ "Failed to update server auto boot: " +
              _ $scope.server_detail.name)
    ]
  .factory '$updateNetworkCom', ['$http', '$window', ($http, $window) ->
    return ($scope, param, type, callback) ->
      serverURL = $CROSS.settings.serverURL
      comURL = "#{serverURL}/#{type}"
      $http.put comURL, param
        .success (data) ->
          callback.success(data)
        .error (err) ->
          callback.error(err)
  ]
  .factory '$updateResource', ['$http', '$window', ($http, $window) ->
    return ($scope, key, value, type) ->
      serverURL = $CROSS.settings.serverURL
      obj = $scope["#{type}_detail"]
      if type == 'image'
        obj = $scope.image
      name = obj.name
      if type == 'volume'
        name = obj.display_name
        body =
          display_name: value
        url = "#{serverURL}/volumes/"
      else if type == 'image'
        body =
          is_public: obj.is_public
          min_disk: obj.min_disk
          min_ram: obj.min_ram
          name: obj.name
        body[key] = value
        url = "#{serverURL}/images/"
      $http.put "#{url}#{$scope.currentId}", body
        .success (data)->
          toastr.success _(["Successfully update %s: %s", _(type), name])
          $scope.$emit("update", data)
        .error (error) ->
          toastr.error _(["Failed to update %s: %s", _(type), name])
    ]
  .factory '$detailShow', () ->
    return ($scope) ->
      if $scope.currentId
        $scope.detail_show = "detail_show"
      else
        $scope.detail_show = "detail_hide"
  .factory '$serverDetail', ['$http', '$window', '$q', ($http,
  $window, $q) ->
    return ($scope, $updateDetail, $watchDeleted, $state,
    $updateServer) ->
      serverUrl = $CROSS.settings.serverURL
      $scope.detailItem = {
        volumeInfo: _("Attached Volumes")
        volume: _("Volume")
        attachTo: _("attached on")
        noneVolume: _("No attached volume")
        secGroups: _("Security groups configuration")
      }
      statusTemplate = '<span class="status" ng-class="source.statusClass"></span>{{source.status}}'

      $scope.detailKeySet = {
        detail: [
          {
            base_info:
              title: _('Detail Info')
              keys: [
                {
                  key: 'securityName'
                  value: _ 'Security Groups'
                  dynamic: true
                },
                {
                  key: 'name'
                  value: _('Name')
                  editable: true
                  restrictions:
                    required: true
                    len: [4, 25]
                  editAction: (key, value) ->
                    $updateServer $scope, key, value
                    return
                },
                {
                  key: 'autoBoot'
                  value: _('Auto Boot')
                  editable: true
                  editType: 'select'
                  default: [{
                    text: _("Enable")
                    value: "Enable"
                  }, {
                    text: _("Disable")
                    value: "Disable"
                  }]
                  editAction: (key, value) ->
                    $updateServer $scope, key, value, 'metadata'
                    return
                },
                {
                  key: 'id'
                  value: _('ID')
                },
                {
                  key: 'status'
                  value: _('Status')
                  template: statusTemplate
                }
                {
                  key: 'imageName'
                  value: _('Image')
                  depend: 'image_name'
                  dynamic: true
                }
                {
                  key: 'hypervisor_hostname'
                  value: _('Host')
                }
                {
                  key: 'project_name'
                  value: _('Project')
                }
                {
                  key: 'user_name'
                  value: _('User')
                }
                {
                  key: 'created'
                  value: _('Create At')
                  type: 'data'
                }
                {
                  key: 'fixed'
                  value: _('FixedIP')
                  template: '<span class="ip-list" ng-repeat="ip in source.fixed">{{ip}}&nbsp;</span>'
                }
                {
                  key: 'floating'
                  value: _('FloatingIP')
                  none:  _("None Floating IP Binded")
                  template: '<span class="ip-list" ng-repeat="ip in source.floating">{{ip}}</span><span class="ip-list" ng-if="source.floating.length==0">{{title.none}}</span>'
                }
              ]
          }
          {
            flavor_info:
              title: _('Flavor Info')
              keys: [
                {
                  key: 'vcpus'
                  value: _('CPU')
                },
                {
                  key: 'ram'
                  value: _('RAM')
                  template: '{{source.ram | unitSwitch:true}}'
                },
                {
                  key: 'disk'
                  value: _('Disk')
                  template: '{{source.disk}}'
                }
              ]
          }
        ]
      }

      labileStatus = [
        'BUILD'
        'MIGRATING'
        'HARD_REBOOT'
        'REBOOT'
        'powering-off'
        'image_pending_upload'
      ]
      $scope.abnormalStatus = [
        'ERROR'
      ]
      $scope.shutdownStatus = [
        'PAUSED'
        'SUSPENDED'
        'STOPPED'
        'SHUTOFF'
      ]

      # Define the security group at instance detail
      $scope.tipsNoInUse = _ "Have no inuse security groups"
      $scope.tipsNoFree = _ "Have no free security groups"
      $scope.loading = false
      $scope.modifyFlag = false
      $scope.secGroupInUse = []
      $scope.secGroupFree = []
      secGroupInUseRecord = []
      secGroupFreeRecord= []
      $scope.secGroups = {
        buttonName: _ "Save Modified"
        inUse: _ "Security groups in use"
        free: _ "Security groups free"
      }

      listDetailedSecurityGroups = ($http, $window, $q, callback) ->
        queryOpts = {}
        if $CROSS.settings.use_neutron
          queryOpts =
            tenant_id: $CROSS.person.project.id
        $cross.networks.listSecurityGroups $http, queryOpts, (err, securityGroups) ->
          if err
            securityGroups = []
            toastr.error _("Failed to get security groups")
          callback securityGroups

      # Function for add security groups
      # --start--
      $scope.addSecGroup = (secGroupName) ->
        angular.forEach $scope.secGroupInUse, (sec, index) ->
          if secGroupName == sec
            $scope.modifyFlag = true
            $scope.secGroupInUse.splice(index, 1)
            $scope.secGroupFree.push sec
      # --end--

      # Function for remove security groups
      # --start--
      $scope.removeSecGroup = (secGroupName) ->
        angular.forEach $scope.secGroupFree, (sec, index) ->
          if secGroupName == sec
            $scope.modifyFlag = true
            $scope.secGroupFree.splice(index, 1)
            $scope.secGroupInUse.push sec
      # --end--

      # Function for watch modifyFlag change to show button
      # --start--
      $scope.$watch 'modifyFlag', (newValue) ->
        $scope.modifyFlag = newValue
      # --end--

      # Function for save security groups modified results
      # --start--
      $scope.saveSecGroupModify = () ->
        $scope.loading = true
        angular.forEach $scope.secGroupInUse, (secGroupName, index) ->
          if secGroupName not in secGroupInUseRecord
            data = {
              addSecurityGroup: {
                name: secGroupName
              }
            }
            $http.post "#{serverUrl}/servers/#{$scope.currentId}/action", data
              .success ->
                $scope.loading = false
                secGroupInUseRecord = angular.copy($scope.secGroupInUse)
                secGroupFreeRecord = angular.copy($scope.secGroupFree)
                toastr.success _ "Add security groups success."
              .error ->
                toastr.error _ "Failed to add security groups."
          else
            $scope.loading = false

        angular.forEach $scope.secGroupFree, (secGroupName, index) ->
          if secGroupName not in secGroupFreeRecord
            data = {
              removeSecurityGroup: {
                name: secGroupName
              }
            }
            $http.post "#{serverUrl}/servers/#{$scope.currentId}/action", data
              .success ->
                $scope.loading = false
                secGroupInUseRecord = angular.copy($scope.secGroupInUse)
                secGroupFreeRecord = angular.copy($scope.secGroupFree)
                toastr.success _ "Remove security groups success."
              .error ->
                toastr.error _ "Failed to remove security groups."
          else
            $scope.loading = false

        $scope.modifyFlag = false
      # --end--

      $updateDetail $scope
      $watchDeleted $scope, $state

      judgeServerStatus = (instance) ->
        if instance.task_state and instance.task_state != 'null'
          $scope.server_detail.statusClass = 'unknow'
          if instance.status in labileStatus
            $scope.server_detail.status = _(instance.status)
          else
            $scope.server_detail.status = _(instance.task_state)
        else
          if instance.status in labileStatus
            $scope.server_detail.statusClass = 'unknow'
          else if instance.status in $scope.shutdownStatus
            $scope.server_detail.statusClass = 'SHUTOFF'
          else
            $scope.server_detail.statusClass = instance.status
          $scope.server_detail.status = _(instance.status)

      $scope.server_detail = ''

      $scope.getServer = () ->
        $cross.serverGet $http, $window, $q, $scope.currentId, (server) ->
          if !server
            $state.go 'project.instance'
            toastr.error _("Failed to get server detail!")
            $scope.server_detail = 'error'
            return
          if server.security_groups
            server.security_groups = JSON.parse server.security_groups
            # Find the current instance's security groups
            angular.forEach server.security_groups, (secGroup, index) ->
              $scope.secGroupInUse.push secGroup.name
              secGroupInUseRecord.push secGroup.name

          # Find free security groups for current instance
          listDetailedSecurityGroups $http, $window, $q, (securityGroups) ->
            angular.forEach securityGroups, (secGroup, index) ->
              if secGroup.name not in $scope.secGroupInUse
                $scope.secGroupFree.push secGroup.name
                secGroupFreeRecord.push secGroup.name

          $scope.server_detail = server
          for volume in server.volumes
            if not volume.volume_name or volume.volume_name == 'null'
              volume.volume_name = _ "Boot volume"
          server.metadata = JSON.parse server.metadata
          if server.metadata.autoBoot
            $scope.server_detail.autoBoot = JSON.parse server.metadata.autoBoot
          else
            $scope.server_detail.autoBoot = false
          if server.disk == 0 or server.disk == "0"
            $scope.server_detail.disk = _ "default"
          else
            $scope.server_detail.disk = server.disk + " GB"
          queryOpts = {}
          $cross.networks.listSecurityGroups $http, queryOpts, (err, securityGroups) ->
            if err
              securityGroups = []
              toastr.error _ "Failed to get security groups"
            else
              $scope.server_detail.security_group = {}
              $scope.server_detail.noneSecGroup = _ "None"
              secGroupNameToId = {}
              serverSecGroup = server.security_groups or [{name: 'Null'}]
              for item in securityGroups
                secGroupNameToId[item.name] = item.id
              for serSecGroup in serverSecGroup
                $scope.server_detail.security_group[secGroupNameToId[serSecGroup.name]] = serSecGroup.name
                $scope.server_detail.securityName = '<a ng-repeat="(secId,secName) in source.security_group track by $index" ui-sref="project.security_group.securityGroupId({ securityGroupId:secId })" ng-if="secName!=\'Null\'">{{secName}}</a><span ng-repeat="(secId, secName) in source.security_group track by $index" ng-if="secName==\'Null\'">{{source.noneSecGroup}}</span>'

          $scope.$emit("detail", server)
          detail_tabs = $scope.$parent.detail_tabs
          # NOTE (ZhengYue): Hidden the unavailable tab
          if server.status == "ERROR"
            for tab, index in detail_tabs
              if tab.url != 'admin.instance.instanceId.overview'
                $scope.$parent.detail_tabs[index].available = false
          judgeServerStatus server
          if $scope.server_detail.image_name == null
            $scope.server_detail.imageName = _("Deleted")
          else
            $scope.server_detail.imageName = '<a ui-sref="admin.image.imageId.overview({ imageId:source.image.id })">{{source.image_name}}</a>'
    ]
  .factory '$volumeDetail', ['$http', '$window', '$q', '$updateDetail',
  '$watchDeleted', '$state', '$stateParams', '$selected',
  '$detailShow', '$updateResource', ($http, $window, $q, $updateDetail,
  $watchDeleted, $state, $stateParams, $selected,
  $detailShow, $updateResource) ->
    class VolumeDetail extends $cross.DetailView
      customScope: ($scope, options) ->
        $scope.note =
          tabTitle: _("Overview")
          attachment:
            info: _("Attach Instance")
            instanceName: _("Instance Name")
            attachDevice: _("Attach at")

        $updateResource = options.$updateResource
        statusTemplate = '<span class="status" ng-class="source.statusClass"></span>{{source.status}}'
        $scope.detailKeySet = {
          detail: [
            {
              base_info:
                title: _('Volume Detail')
                keys: [
                  {
                    key: 'display_name'
                    value: _('Name')
                    editable: true
                    restrictions:
                      required: true
                      len: [4, 25]
                    editAction: (key, value) ->
                      $updateResource $scope, key, value, 'volume'
                      return
                  },
                  {
                    key: 'id'
                    value: _('ID')
                  }
                  {
                    key: 'size'
                    value: _('Size')
                    template: '<span>{{source.size}} GB</span>'
                  }
                  {
                    key: 'volume_type'
                    value: _('Performance Type')
                  }
                  {
                    key: 'status'
                    value: _('Status')
                    template: statusTemplate
                  }
                  {
                    key: 'host'
                    value: _('Host')
                  }
                  {
                    key: 'project'
                    value: _('project')
                  }
                  {
                    key: 'created_at'
                    value: _('Created')
                    type: 'data'
                  }
                  {
                    key: 'display_description'
                    value: _('Description')
                  },
                ]
            }
          ]
        }
        return

      getDetail: ($scope, options) ->
        $window = options.$window
        $http = options.$http
        $q = options.$q
        serverUrl = $window.$CROSS.settings.serverURL

        labileStatus = [
          'creating'
          'error_deleting'
          'deleting'
          'attaching'
          'detaching'
          'downloading'
        ]

        judgeVolumeStatus = (volume) ->
          if volume.status in labileStatus
            $scope.volume_detail.statusClass = 'unknow'
            $scope.volume_detail.status = _ volume.status
          else if volume.status == 'available'
            $scope.volume_detail.statusClass = 'ACTIVE'
            $scope.volume_detail.status = _ volume.status
          else
            $scope.volume_detail.statusClass = 'SHUTOFF'
            $scope.volume_detail.status = _ volume.status

        $http.get "#{serverUrl}/volumes/#{$scope.currentId}"
          .success (volume) ->
            $scope.volume_detail = volume
            volume.host = volume["os-vol-host-attr:host"]
            if not volume.display_name || volume.display_name == 'null'
              volume.display_name = _("Unnamed")
            judgeVolumeStatus volume

            https = []
            https[0] = $http.get("#{serverUrl}/projects/query", {
              params:
                ids: '["' + volume.tenant_id + '"]'
                fields: '["name"]'
            })
            volume.attachments = JSON.parse volume.attachments
            if volume.attachments.length
              https[1] = $http.get("#{serverUrl}/servers/query", {
                params:
                  ids: '["' + volume.attachments[0].server_id + '"]'
                  fields: '["name"]'
              })
            $q.all(https)
              .then (rs) ->
                project = rs[0].data
                if volume.attachments.length
                  server = rs[1].data
                  volume.attachDevice = volume.attachments[0].device
                  server_id = volume.attachments[0].server_id
                  volume.attachment = server[server_id].name
                else
                  volume.attachment = _("Not attached to any instances")
                  volume.attachDevice = ''
                if project[volume.tenant_id]
                  volume.project = project[volume.tenant_id].name
                else
                  volume.project = volume.tenant_id
              , (err) ->
                volume.attachment = _("Not attached to any instances")
                volume.attachDevice = ''
    return ($scope, options) ->
      volumeDetail = new VolumeDetail(options)
      volumeDetail.init($scope, {
        $http: $http
        $q: $q
        $window: $window
        $state: $state
        $stateParams: $stateParams
        $selected: $selected
        $detailShow: $detailShow
        $updateDetail: $updateDetail
        $watchDeleted: $watchDeleted
        $updateResource: $updateResource
      })
    ]
  .factory '$imageDetail', ['$http', '$window', '$q', '$updateDetail',
  '$watchDeleted', '$state', '$stateParams', '$selected',
  '$detailShow', '$updateResource', ($http, $window, $q, $updateDetail,
  $watchDeleted, $state, $stateParams, $selected,
  $detailShow, $updateResource) ->
    class ImageDetail extends $cross.DetailView
      customScope: ($scope, options) ->
        $scope.note =
          tabTitle: _("Overview")
          detail:
            advanceConfig: _("Advance config")
            add: _("Add properties")
            save: _("Save")
            edit: _("Edit")
            cancel: _("Cancel")
            username: _("Username")
            password: _("Password")
            osType: _("OS type")
            min_ram: _("Min ram")
            min_disk: _("Min disk")
            config: _("Configuration")
            propertiesEmpty: _("no properties")
            description: _("Description")
        $updateResource = options.$updateResource
        statusTemplate = '<span class="status" ng-class="source.statusClass"></span>{{source.status}}'
        $scope.detailKeySet = {
          detail: [
            {
              base_info:
                title: _("Image Detail")
                keys: [
                  {
                    key: 'name'
                    value: _('Name')
                    editable: true
                    restrictions:
                      required: true
                      len: [4, 25]
                    editAction: (key, value) ->
                      $updateResource $scope, key, escape(value), 'image'
                      return
                  },
                  {
                    key: 'id'
                    value: _('ID')
                  },
                  {
                    key: 'size'
                    value: _('Size')
                  },
                  {
                    key: 'status'
                    value: _('Status')
                    template: statusTemplate
                  },
                  {
                    key: 'is_public'
                    value: _('Is public')
                    editable: true
                    editType: 'select'
                    default: [{
                      text: _("Public")
                      value: true
                    }, {
                      text: _("Private")
                      value: false
                    }]
                    editAction: (key, value) ->
                      $updateResource $scope, key, value, 'image'
                      return
                  },
                  {
                    key: 'disk_format'
                    value: _('Disk format')
                    editable: true
                    editType: 'select'
                    default: [{
                      text: "qcow2"
                      value: "qcow2"
                    }, {
                      text: "iso"
                      value: "iso"
                    }, {
                      text: "raw"
                      value: "raw"
                    }, {
                      text: "vdi"
                      value: "vdi"
                    }, {
                      text: "vhd"
                      value: "vhd"
                    }, {
                      text: "vmdk"
                      value: "vmdk"
                    }]
                    editAction: (key, value) ->
                      $updateResource $scope, key, value, 'image'
                      return
                  },
                  {
                    key: 'container_format'
                    value: _('Container format')
                  },
                  {
                    key: 'created_at'
                    value: _('Created')
                    type: 'data'
                  }
                ]
            }
          ]
        }
        if options.$state.current.name.indexOf('project') == 0
          keys = $scope.detailKeySet.detail[0].base_info.keys
          for item in keys
            if item.key == 'name'
              delete item.editable
            if item.key == 'is_public'
              delete item.editable
            if item.key == 'disk_format'
              delete item.editable

        $scope.edit = ->
          $scope.editing = true

        $scope.cancel = ->
          $scope.editing = false

        $scope.editing = false

        $scope.tips = {}
        $scope.save = ->
          $scope.editing = false
          img = $scope.image
          modal = $scope.modal
          serverUrl = $CROSS.settings.serverURL
          body =
            min_ram: parseInt(modal.minRam)
            min_disk: parseInt(modal.minDisk)
          properties = $scope.modal.properties || {}
          if modal.username != undefined
            properties.username = modal.username
          if modal.password != undefined
            properties.password = modal.password
          if modal.description != undefined
            properties.description = modal.description
          if modal.osType != undefined
            properties.os_type = modal.osType
          if modal.properties != undefined
            properties.vmware_adaptertype = modal.vmware_adaptertype
          if modal.extProperties
            for ky of modal.extProperties
              if modal.extProperties[ky] != "undefined" \
              and modal.extProperties[ky] != undefined
                properties[ky] = modal.extProperties[ky]
          for ky of $scope.modal.properties
              if $scope.modal.properties[ky] != "undefined" \
              and $scope.modal.properties[ky] != undefined
                properties[ky] = $scope.modal.properties[ky]
          pro = {}
          for k of properties
            if properties[k] != "undefined" \
            and properties[k] != undefined
              val = properties[k]
              k = escape(k)
              pro[k] = escape(val)
          body['properties'] = pro

          $http.put "#{serverUrl}/images/#{$scope.currentId}", body
            .success (image) ->
              toastr.success _("Successfully update image: ") + $scope.image.name
              $scope.initial image
              $scope.cancel()
            .error (err) ->
              console.error "Failed to update server:", err
              toastr.error _("Failed to update image: ") + $scope.image.name

        validKeyOrValue = (val, isKey) ->
          if val == undefined or val == ""
            if isKey
              $scope.tips['self_define'] = _("Key could not be empty")
              return false
            return true
          if isKey
            if $scope.modal.properties[val] != undefined
              $scope.tips['self_define'] = _("Key is already exist")
              return
          if val.length > 32
            $scope.tips['self_define'] = _("Length must be shorter than 33")
            return
          $scope.tips['self_define'] = ""
          return true

        $scope.valid = (val, isKey) ->
          validKeyOrValue(val, isKey)

        $scope.defineAdd = ->
          if not validKeyOrValue($scope.modal.defineKey, true)
            return
          if not validKeyOrValue($scope.modal.defineValue)
            return
          key = $scope.modal.defineKey
          value = $scope.modal.defineValue
          $scope.modal.properties[key] = value
          $scope.modal.defineKey = ""
          $scope.modal.defineValue = ""
          if Object.keys($scope.modal.properties).length
            $scope.modal.showExtpro = true if not $scope.modal.showExtpro

        $scope.defineMinues = (key) ->
          delete $scope.modal.properties[key]
          if not Object.keys($scope.modal.properties).length
            if not Object.keys($scope.modal.extProperties).length
              $scope.modal.showExtpro = false
        return
      getDetail: ($scope, options) ->
        $window = options.$window
        $http = options.$http
        $q = options.$q
        serverUrl = $window.$CROSS.settings.serverURL

        osTypes = [{
          text: _("windows")
          value: 'windows'
        }, {
          text: _("linux")
          value: 'linux'
        }]
        if $window.$CROSS.settings.osTypes
          osTypes = []
          for os in $window.$CROSS.settings.osTypes
            item =
              text: os
              value: os
            osTypes.push item

        $scope.osDefault = osTypes

        $scope.initial = (image) ->
          if image.status == 'active'
            image.statusClass = 'ACTIVE'
          else
            image.statusClass = 'SHUTOFF'
          image.status = _(image.status)
          image.size = $cross.utils.getByteFix image.size
          if typeof image.properties == 'string'
            image.properties = JSON.parse image.properties
          extProperties = {}
          is_public = image.is_public == 'true' or image.is_public == true
          $scope.modal =
            defineKey: ""
            defineValue: ""
            name: image.name
            minRam: image.min_ram
            minDisk: image.min_disk
            is_public: is_public
          image.is_public = is_public
          image.properties.username = unescape image.properties.admin_username \
          || image.properties.username || _ "null"
          image.properties.password = unescape image.properties.admin_pass \
          || image.properties.password || _ "null"
          image.properties.description = unescape image.properties.description || _ "null"
          $scope.image = image

          if image.properties.username != undefined
            $scope.modal.username = image.properties.username
          if image.properties.password != undefined
            $scope.modal.password = image.properties.password
          if image.properties.description != undefined
            $scope.modal.description = image.properties.description
          if image.properties.vmware_adaptertype != undefined
            $scope.modal.vmware_adaptertype = image.properties.vmware_adaptertype
          $scope.modal.osType = $scope.osDefault[0].value
          if image.properties.os_type != undefined
            if image.properties.os_type != "None"
              $scope.modal.osType = image.properties.os_type
            else
              delete $scope.image.properties.os_type
          $scope.modal.showHigher = false
          if image.properties.image_type != 'backup' and image.properties.image_type != 'snapshot'
            $scope.modal.showHigher = true
          $scope.modal.extProperties = extProperties
          for key of image.properties
            if key == 'username' || key == 'password' || key == 'description' \
            || key == 'os_type' || key == 'vmware_adaptertype'|| key == 'vmware_disktype'
              continue
            if image.properties[key] == null
              extProperties[key] = undefined
            else if typeof image.properties[key] != 'string'
              extProperties[key] = JSON.stringify image.properties[key]
            else
              extProperties[key] = image.properties[key]
          $scope.modal.properties = extProperties

        $http.get "#{serverUrl}/images/#{$scope.currentId}"
          .success (image) ->
            img = {}
            for k of image
              val = image[k]
              img[k] = unescape(val)
            $scope.initial img
          .error (err) ->
            toastr.error _("Failed to get image detail.")
    return ($scope, options) ->
      imageDetail = new ImageDetail(options)
      imageDetail.init($scope, {
        $http: $http
        $q: $q
        $window: $window
        $state: $state
        $stateParams: $stateParams
        $selected: $selected
        $detailShow: $detailShow
        $updateDetail: $updateDetail
        $watchDeleted: $watchDeleted
        $updateResource: $updateResource
      })
    ]
