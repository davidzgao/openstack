'use strict'

angular.module('Cross.admin.instance')
  .controller 'admin.instance.InstanceActionCtrl', ($scope, $http, $window) ->
    $scope.serverAction = (instanceId, action) ->
      $cross.instanceAction action, $http, $window, instanceId, callback
  .controller 'admin.instance.SnapshotCreatCtrl', ($scope, $http,
  $window, $q, $stateParams, $state, $rootScope, $gossipService,
  getCinderQuota, randomName, getAttachVolFromServer) ->
    _parseBacObject = (snapshotObject) ->
      volSize = 0
      volNum = 0
      for item of snapshotObject
        volSize += JSON.parse snapshotObject[item].size
        volNum++
      return [volNum, volSize]

    $snapshotModal = (new SnapshotCreateModal()).initial($scope,
      {
        $state: $state,
        $http: $http,
        instanceId: $stateParams.instId,
        $window: $window
        $rootScope: $rootScope
        $gossipService: $gossipService
        $randomName: randomName
      })
    hypervisor_type = $CROSS.settings.hypervisor_type.toLocaleLowerCase()
    getCinderQuota((quota) ->
      $scope.cinderQuota = quota
    )
    $scope.form['warningInfo'] = _ "Warning: the vsphere 5.0 create \
                                    snapshot not supported."
    $scope.form['warningFlag'] = if hypervisor_type == 'vmware'\
                                 then true else false
    serverUrl = $window.$CROSS.settings.serverURL
    $http.get "#{serverUrl}/servers/#{$stateParams.instId}"
      .success (server) ->
        getAttachVolFromServer server, $scope
        $scope.server = server
      .finally ->
        $snapshotModal.clearLoading()

    $scope.volumeClick = (vol) ->
      if vol.selected and vol.bootable != 'true'
        vol.selected = false
        for item, index in $scope.form['snapshot_object']
          if item and vol.id == item.id
            $scope.form['snapshot_object'].splice index, 1
      else if vol.bootable != 'true'
        vol.selected = true
        $scope.tips['snapshot_object'] = ''
        for item in $scope.form['snapshot_object']
          if item and vol.id == item.id
            return
        $scope.form['snapshot_object'].push vol

  .controller 'admin.instance.MigrateCtrl', ($scope, $http,
  $window, $q, $stateParams, $state, $rootScope) ->
    (new MigrateModal()).initial($scope, {
      $state: $state,
      $http: $http,
      instanceId: $stateParams.instId,
      $window: $window
      $rootScope: $rootScope
    })
    $scope.note.modal.save = _("Confirm")
    # Get available host inject to fields
    serverUrl = $window.$CROSS.settings.serverURL
    params = {instanceId: $stateParams.instId}
    clusterHttp = $http.get "#{serverUrl}/os-aggregates"
    server = $http.get "#{serverUrl}/servers/#{$stateParams.instId}"
    $q.all([clusterHttp, server])
      .then (values) ->
        clusters = values[0].data
        serverDetail = values[1].data
        currentHost = serverDetail['OS-EXT-SRV-ATTR:hypervisor_hostname']
        availHosts = []
        hyperDict = {}
        for cluster in clusters
          if currentHost not in cluster.hosts
            continue
          for host in cluster.hosts
            if host == currentHost
              continue
            else
              item =
                text: host
                value: host
              availHosts.push item
        if availHosts.length == 0
          fill =
            text: _("No available host.")
            value: -1
          availHosts.push fill
        $scope.modal.fields[0].default = availHosts
        $scope.form.host = availHosts[0].value

class SnapshotCreateModal extends $cross.Modal
  title: "Create Snapshot"
  slug: "create_snapshot"

  fields: ->
    [{
      slug: "name"
      label: _ "Snapshot Name"
      tag: "input"
      restrictions:
        required: true
    }
    {
      slug: "snapshot_object"
      label: _ "Snapshot Object"
      tag: "mulit-select"
    }
    ]

  handle: ($scope, options) ->
    form = $scope.form
    serverUrl = $CROSS.settings.serverURL
    dataVolume = []
    projectId = $CROSS.person.project.id
    userId = $CROSS.person.user.id
    $http = options.$http
    $randomName = options.$randomName
    for item of form['snapshot_object']
      if form['snapshot_object'][item].bootable == 'true'
        systemVolume = form['snapshot_object'][item].id
      else
        dataVolume.push form['snapshot_object'][item]

    for volume in dataVolume
      volData =
        display_name: volume.display_name.slice(4) + "--backup"
        source_volid: volume.id
        size: parseInt volume.size
      $http.post "#{serverUrl}/volumes", volData
        .success (data) ->
          msg = "Successed to create data volume backup: %s"
          toastr.success _([msg, data.display_name])
        .error (err) ->
          msg = "Meet error when create data volume backup: %s"
          toastr.error _([msg, data.display_name])
          console.error err
          options.callback false

    if $scope.server.image
      $scope.params =
        name: $scope.form.name
        metadata: {}
      $scope.params.instanceId = options.instanceId
      message =
        object: "instance-#{$scope.server.id}"
        priority: 'info'
        loading: 'true'
        content: _(["Instance %s is %s ...", $scope.server.name, _("creating backup")])
      options.$gossipService.receiveMessage message
      $cross.instanceAction 'snapshot', $http, options.$window,
      $scope.params, (status) ->
        if status == 200
          options.$rootScope.$broadcast('actionSuccess', options.instanceId)
          options.$state.go "admin.instance"
          return
      options.callback false
      return true
    else
      params =
        name: "VM snapshot_#{$randomName(8)}"
        timeout: 100
        parameters: {}
        template:
          type: 'HL:Cinder:Snapshot'
          task_type: 'thread'
          interval: '0'
          system_volume: systemVolume
          data_volumes: []
          snapshot_name: $scope.form['name']
          project_id: projectId
          user_id: userId
      $http.post "#{serverUrl}/rules", params
        .success (rule) ->
          options.callback true
          toastr.success _(["Instance %s is %s ...", $scope.server.name, _("creating backup")])
        .error (err) ->
          options.callback false
          console.error "Meet error: #{err}"

  close: ($scope, options) ->
    options.$state.go "admin.instance"

class MigrateModal extends $cross.Modal
  title: "Migrate"
  slug: "migrate"

  fields: ->
    [{
      slug: "host"
      label: _ "Destination Host"
      tag: "select"
      restrictions:
        required: true
    }]

  handle: ($scope, options) ->
    if $scope.form.host == -1
      $scope.tips['host'] = _("Cannot be empty.")
      options.callback false
      return
    $scope.params = {
      disk_over_commit: true
      block_migration: false
      host: $scope.form.host
    }
    $scope.params.instanceId = options.instanceId
    $cross.instanceAction 'live-migrate', options.$http, options.$window, $scope.params, (status) ->
      if status == 200
        detail = {
          id: options.instanceId
          type: 'instance'
        }
        # NOTE(ZhengYue): Send broadcast to each child scope to
        # notify action success.
        options.$rootScope.$broadcast('actionSuccess', detail)
        options.$state.go "admin.instance"
        toastr.success _(["Success to migrate instance to host %s", $scope.form.host])
        return
      toastr.error _(["Failed to migrate instance to host %s", $scope.form.host])
      options.callback false
    return true

  close: ($scope, options) ->
    options.$state.go "admin.instance"
