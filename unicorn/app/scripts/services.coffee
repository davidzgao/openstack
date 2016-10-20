'use strict'

###
 # @description
 # # The services module of Unicorn
 #
 # loginCheck service is used for user is login or not
###

angular.module('Unicorn.services', [])
  .factory 'randomName', () ->
    return (num) ->
      chars = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0',\
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l',\
      'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x',\
      'y', 'z']
      res = ''

      for n in [1..num]
        id = Math.ceil(Math.random() * 35)
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
      serverUrl = $UNICORN.settings.serverURL
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
              volName = _("System Volume") + ":" + volume.display_name
            else
              volName = _("Data Volume") + ":" + volume.display_name
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
      serverUrl = $UNICORN.settings.serverURL
      projectId = $UNICORN.person.project.id
      $http.get "#{serverUrl}/cinder/os-quota-sets/#{projectId}?usage=true"
        .success (quota) ->
          callback quota
        .error (err) ->
          console.error "Failed to get cinder quota: #{err}"
  ]
  .factory 'tryApply', ['$http', '$q', ($http, $q) ->
    return (options) ->
      quotas  = $http.get "#{options.serverUrl}/#{options.service}/os-quota-sets/#{options.projectId}?usage=true"
      httpRes = [quotas]
      if options.useNeutron
        floatings = $http.get "#{options.serverUrl}/floatingips"
        httpRes.push floatings
      $q.all httpRes
        .then (res) ->
          if options.useNeutron && res[1]
            floatingList = res[1].data
          if res[0]
            quota = res[0].data
            if floatingList
              floatingIPNum = 0
              floatingList.forEach (item) ->
                  if item.tenant_id == options.projectId
                    floatingIPNum += 1
            if quota[options.type]['in_use'] >= quota[options.type]['limit']\
            or floatingIPNum >= quota[options.type]['limit']
              toastr.error _(["Sorry, you have no more quota to get new %s",\
                _ options.type])
            else
              options.callback.apply this, options.callbackParams
              return
        .catch (err) ->
          toastr.error _ (["Get server quota error: %s", err.data.error_description])
  ]
  .factory '$logincheck', ['$location','$q','$injector','$window', '$rootScope', ($location, $q, $injector, $window, $rootScope) ->
    return {
      responseError: (response) ->
        # Sign out if the user is no longer authorized.
        if response.status == 401 \
        or (response.data and response.data.status == 401)
          hash = location.hash
          if $rootScope.unautherized
            if hash == '#/login'
              return $q.reject(response)
            $location.path("/login")
            return
          $rootScope.unautherized = true
          if hash != '#/login' and hash != '#/forgetpassword'
            $location.path("/login")
            toastr.warning _("Session timeout, please login again")
            return

        if response.status == 0
          err_data = {"error_description": "Could not connect to the server"}
          response.data = err_data

        return $q.reject(response)
    }]
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
  .factory '$listWorkflowService', ['$http', '$window', ($http,
  $window) ->
    return ($scope) ->
      serverURL = $window.$UNICORN.settings.serverURL
      workflows = "#{serverURL}/workflow-request-types"
      $http.get workflows
        .success (data, status, headers) ->
          $scope.workflows = data
        .error (error) ->
          $scope.workflows = []
          toastr.error _("Error at get service list!")
  ]
  .factory '$desktopLogin', ['$http', '$window', ($http, $window) ->
    return (authInfo, callback) ->
      # Do not login desktop if cloud_desktop in settings is undefined.
      cloud_desktop = $UNICORN.settings.cloud_desktop
      if not cloud_desktop
        callback()
        return true

      # NOTE(ZhengYue): Post message to desktop page.
      # There may be a security problem at here, so if deploy
      # this web app on public network, set sharedDomain be needed.
      ifm = document.getElementById('cloud_desktop')
      sharedDomain = $window.$UNICORN.settings.sharedDomain or '*'
      ifm.contentWindow.postMessage(JSON.stringify(authInfo), sharedDomain)
      # FIXME(ZhengYue): SetTimeout 2 seconds after callback for waitting
      # receive message at desktop service.
      setTimeout(() ->
        callback()
      , 2000)
  ]
  .factory '$updateResource', ['$http', '$window', ($http, $window) ->
    return ($scope, key, value, type) ->
      serverURL = $UNICORN.settings.serverURL
      if type == 'volume'
        body =
          display_name: value
        url = "#{serverURL}/volumes/"
      else if type == 'image'
        body =
          name: value
      else if type == 'backup'
        body =
          name: value
          properties:
            image_type: "snapshot"
        url = "#{serverURL}/images/"
      $http.put "#{url}#{$scope.currentId}", body
        .success (data)->
          toastr.success _("Successfully update") + _(type) + value
          $scope.$emit("update", data)
        .error (error) ->
          toastr.error(_ "Failed to update" + _(type) +
            $scope["#{type}_detail"].name)
    ]

  .factory '$gossipService', ["$rootScope", "$window", ($rootScope,
  $window) ->
    _handleMessage = (message) ->
      if not $window.$UNICORN.person
        return
      message = message || {}
      if not toastr[message.priority]
        return
      opts = undefined
      if message.loading
        opts =
          iconClass: 'toast-loading'
          progressBar: true
          timeOut: 60000
      if not $unicorn.gossip.msgQueue[message.object]
        trs = toastr[message.priority](message.content, null, opts)
        objId = "_message-#{message.object}"
        trs.attr('id', objId)
        $unicorn.gossip.msgQueue[message.object] = objId
      else
        objId = $unicorn.gossip.msgQueue[message.object]
        obj = angular.element "##{objId}"
        if obj.length
          obj.removeClass 'toast-loading'
          obj.removeClass 'toast-info'
          obj.removeClass 'toast-success'
          obj.removeClass 'toast-warning'
          obj.removeClass 'toast-error'
          obj.addClass "toast-#{message.priority}"
          obj.html(message.content)
          if not message.loading
            if toastr.options.timeOut > 0
              setTimeout ->
                obj.slideUp()
                toastr.remove obj
                delete $unicorn.gossip.msgQueue[message.object]
              , toastr.options.timeOut
        else
          trs = toastr[message.priority](message.content, null, opts)
          objId = "_message-#{message.object}"
          trs.attr('id', objId)
          $unicorn.gossip.msgQueue[message.object] = objId

    return {
      receiveMessage: (message) ->
        _handleMessage message

      updateMessage: (message) ->
        _handleMessage message
        $rootScope.$broadcast "$gossipService.#{message.meta.tag}", message.meta
        switch message.meta.event
          when "instance.volume.attach"
            message.meta.isInstance = true
            $rootScope.$broadcast "$gossipService.volume", message.meta
          when "instance.volume.detach"
            message.meta.isInstance = true
            $rootScope.$broadcast "$gossipService.volume", message.meta
          when "instance.floating_ip.associate"
            message.meta.isInstance = true
            $rootScope.$broadcast "$gossipService.floating_ip", message.meta
          when "instance.floating_ip.disassociate"
            message.meta.isInstance = true
            $rootScope.$broadcast "$gossipService.floating_ip", message.meta
    }
  ]
