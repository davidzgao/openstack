'use strict'

angular.module('Unicorn.dashboard.volume')
  .controller 'dashboard.volume.VolumeDetailCtr', ($scope, $http,
  $window, $q, $stateParams, $state) ->
    $scope.detail_tabs = [
      {
        name: _('Overview'),
        url: 'dashboard.volume.volumeId.overview',
        available: true
      }
    ]

    volumeDetail = new $unicorn.DetailView()
    volumeDetail.init($scope, {
      itemId: $stateParams.volumeId
      $state: $state
    })

  .controller 'dashboard.volume.VolumeOverviewCtr', ($scope, $http,
  $window, $q, $stateParams, $state, $updateResource) ->

    $scope.currentId = $stateParams.volumeId
    $scope.$emit('tabDetail')
    $scope.note =
      detail:
        info: _("Volume Detail")
        id: _("ID")
        name: _("Name")
        status: _("Status")
        type: _("Type")
        host: _("Host")
        project: _("Project")
        description: _("Description")
        size: _("Size")
        created_at: _("Created")
      attachment:
        info: _("Attach Instance")
        instanceName: _("Instance Name")
        attachDevice: _("Attach to")

    # Get server detail info and judge action set for instance
    serverUrl = $window.$UNICORN.settings.serverURL
    getVolume = () ->
      $http.get "#{serverUrl}/volumes/#{$scope.currentId}"
        .success (volume) ->
          $scope.volume_detail = volume
          volume.host = volume["os-vol-host-attr:host"]
          if not volume.display_name || volume.display_name == 'null'
            volume.display_name = _("Unnamed")
          $scope.volume_detail.status = _(volume.status)

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
                volume.attachments = server[server_id].name
              else
                volume.attachments = _("Not attached to any instances")
              if project[volume.tenant_id]
                volume.project = project[volume.tenant_id].name
              else
                volume.project = volume.tenant_id
            , (err) ->
              console.log err, "Failed to get projects/servers name"

    getVolume()

    $scope.detailKeySet = {
      detail: [
        base_info:
          title: _("Volume Detail")
          keys: [
            {
              key: 'display_name'
              value: _("Name")
              editable: true
              restrictions:
                required: true
                len: [4, 25]
              editAction: (key, value) ->
                # update volume $scope, key, value
                $updateResource $scope, key, value, 'volume'
                return
            },
            {
              key: 'id'
              value: _("ID")
            },
            {
              key: 'size'
              value: _("Size")
              unit: 'GB'
            },
            {
              key: 'status'
              value: _("Status")
            },
            {
              key: 'created_at'
              value: _("Created")
              type: 'data'
            }
          ]
      ]
    }
