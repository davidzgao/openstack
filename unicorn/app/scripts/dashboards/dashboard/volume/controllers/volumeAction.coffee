'use strict'

angular.module('Unicorn.dashboard.volume')
  .controller 'dashboard.volume.VolumeActionCtrl', ($scope, $http,
  $window, $q, $stateParams, $state) ->
    return true

  .controller 'dashboard.volume.snapshotCreateCtrl', ($scope, $http,
  $window, $q, $stateParams, $state, $gossipService) ->
    (new SnapshotCreateModal()).initial($scope,
      {
        $state: $state,
        $http: $http,
        volId: $stateParams.volId,
        $window: $window
      })

  .controller 'dashboard.volume.VolumeAttachCtrl', ($scope, $http,
  $window, $q, $stateParams, $state, $gossipService) ->
    volId = $stateParams.volId
    $attachModal = (new VolumeAttachModal()).initial($scope, {
      $state: $state
      $http: $http
      volId: volId
      $window: $window
      $gossipService: $gossipService
    })
    # initial warning infos
    hypervisor_type = $UNICORN.settings.hypervisor_type
    $scope.form['warningInfo'] = _ "Notice: volume can only attach to instance \
                                    which has powered off."
    $scope.form['warningFlag'] = if hypervisor_type \
                                 and hypervisor_type.toLocaleLowerCase() == 'vmware'\
                                 then true else false

    $scope.note.modal.save = _("Attach")
    # initial volume list.
    serverUrl = $window.$UNICORN.settings.serverURL
    volueHttp = $http.get "#{serverUrl}/volumes/#{volId}"
    serverHttp = $http.get "#{serverUrl}/servers"
    $q.all [volueHttp, serverHttp]
      .then (res) ->
        volume = res[0].data
        if volume and volume.attachments
          attachments = JSON.parse volume.attachments
          if attachments.length
            toastr.warning _("Current volume had alreay attached.")
            return
        $scope.volume = volume
        servers = res[1].data.data
        # initial server
        instances = []
        ints = {}
        unableStatus = ['ERROR', 'error', 'deleting', 'UNKNOWN', 'BUILD']
        if hypervisor_type\
        and hypervisor_type.toLocaleLowerCase() == 'vmware'
          unableStatus.push 'ACTIVE'
        for server in servers
          if server.status in unableStatus
            continue
          item =
            text: server['name'] || server['id']
            value: server['id']
          ints[server['id']] = server['name']
          instances.push item
        $scope.instances = ints
        if not instances.length
          instances.push {text: _("No available"), value: -1}
        $scope.modal.fields[0].default = instances
        $scope.form['instance'] = instances[0].value
      .finally ->
        $attachModal.clearLoading()

class SnapshotCreateModal extends $unicorn.Modal
  title: "Create Snapshot"
  slug: "create_snapshot"

  fields: ->
    [{
      slug: "name"
      label: _ "Snapshot Name"
      tag: "input"
      restrictions:
        required: true
        len: [1, 32]
    }
    {
      slug: "description"
      label: _ "Description"
      tag: "textarea"
      restrictions:
        len: [1, 255]
    }]

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    serverUrl = $UNICORN.settings.serverURL
    params = {
      display_name: $scope.form.name
      volume_id: options.volId
      force: false
    }
    if $scope.form['description']
      params['display_description'] = $scope.form['display_description']
    $http.post("#{serverUrl}/cinder/snapshots", params)
      .success (rs) ->
        options.callback false
        toastr.success _("Successfully create volume backup: ") + params.display_name
        $state.go "dashboard.volume", {tab: 'backup'}
      .error (err, status) ->
        toastr.error _("Failed to create volume backup: ") + params.display_name

class VolumeAttachModal extends $unicorn.Modal
  title: "Attach Volume"
  slug: "attach_volume"

  fields: ->
    [{
      slug: "instance"
      label: _ "Instance"
      tag: "select"
      restrictions:
        required: true
    }]

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    serverUrl = $UNICORN.settings.serverURL
    form = $scope.form
    if form['instance'] == -1
      $scope.tips['instance'] = _("No available instances")
      return
    volId = options.volId
    data =
      server: volId
    if form['montpoint']
      data['device'] = form['montpoint']
    insId = form['instance']
    volume = $scope.volume
    name = volume.display_name || volume.id
    message =
      object: "instance-#{insId}"
      priority: 'info'
      loading: 'true'
      content: _(["Instance %s is %s %s ...", $scope.instances[insId], _("attaching"), name])
    options.$gossipService.receiveMessage message
    $http.post "#{serverUrl}/servers/#{insId}/os-volume_attachments", data
      .success ->
        options.callback false
        $state.go "dashboard.volume", null, {reload: true}
      .error (error) ->
        toastr.error _("Failed to attach volume: ") + name
        options.callback false
