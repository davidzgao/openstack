'use strict'

###*
 # @ngdoc function
 # @name Cross.project.volume:VolumeCreateCtrl
 # @description
 # # VolumeCreateCtrl
 # Controller of the Cross
###
angular.module('Cross.project.volume')
  .controller 'project.volume.VolumeCreateCtr', ($scope, $http, $window, $q,
                                         $state, $interval, $templateCache,
                                         $compile, $animate, $gossipService) ->
    serverUrl = $window.$CROSS.settings.serverURL
    $createModal = new VolumeCreateModal()
    $createModal.initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state,
      $gossipService: $gossipService})

    # default source.
    $scope.form['source'] = $scope.modal.fields[4].default[0].value

    # initial images.
    queryOpts =
      params:
        all_tenants: true
        is_public: 'true'
    imageHttp = $http.get "#{serverUrl}/images"
    pubImageHttp = $http.get "#{serverUrl}/images", queryOpts
    bootVolumeHttp = $http.get "#{serverUrl}/volumes?bootable=true"
    volumeSnapHttp = $http.get "#{serverUrl}/cinder/snapshots"
    projectId = $CROSS.person.project.id
    quotaHttp = $http.get "#{serverUrl}/cinder/os-quota-sets/#{projectId}?usage=true"
    volumeTypeHttp = $http.get "#{serverUrl}/volume_types"
    $q.all [imageHttp, pubImageHttp, bootVolumeHttp, volumeSnapHttp, quotaHttp, volumeTypeHttp]
      .then (res) ->
        images = res[0].data.data
        pubImgs = res[1].data.data
        bootVolumes = res[2].data.data
        volumeSnaps = res[3].data
        quota = res[4].data
        volumeType = res[5].data
        basicImgs = []
        basicImgsIgnore = []
        snapshots = []
        volumes = []
        sizeRe = {}
        volumeTypeList = []
        for type in volumeType
          item =
            text: type.name
            value: type.id
          volumeTypeList.push item

        $scope.modal.fields[2].type = 'hidden'
        if $CROSS.settings.useFederator
          $scope.modal.fields[2].type = 'text'
          $scope.modal.fields[2].default = volumeTypeList
          # default type.
          $scope.form['type'] = $scope.modal.fields[2].default[0].value

        for image in images
          pro = image.properties
          item =
            text: image.name
            value: image.id
          imgSize = Number(image.size) / 1024 / 1024 / 1024
          imgMinSize = Number(image.min_disk)
          sizeRe["image_#{image.id}"] = Math.max(imgSize, imgMinSize)
          basicImgs.push item
          basicImgsIgnore.push item.value

        for image in pubImgs
          pro = image.properties
          item =
            text: image.name
            value: image.id
          imgSize = Number(image.size) / 1024 / 1024 / 1024
          imgMinSize = Number(image.min_size)
          sizeRe["image_#{image.id}"] = Math.max(imgSize, imgMinSize)
          if item.value not in basicImgsIgnore
            basicImgs.push item
            basicImgsIgnore.push item.value

        for vol in bootVolumes
          volImgMeta = JSON.parse vol.volume_image_metadata
          item =
            text: vol.display_name
            value: vol.id
          sizeRe['volume_#{item.id}'] = Number(vol.size)
          volumes.push item

        for snp in volumeSnaps
          for vol in volumes
            if vol.value == snp.volume_id
              item =
                text: snp.display_name
                value: snp.id
              sizeRe["snapshot_#{snp.id}"] = sizeRe["volume_#{vol.value}"]
              snapshots.push item
              break
        $scope.modal.source =
          image: basicImgs
          volume: volumes
          snapshot: snapshots
        $scope.sourceSize = sizeRe
        $scope.quota = quota
      .catch (err) ->
        # TODO(Li Xipeng): Handle get image list error.
        toastr.error _("Failed to get images.")
      .finally ->
        # NOTE(Liu Haobo):
        # if the in use resource is less then the quota set
        #   continue create resource
        # else
        #   it will call a reminder to warn user that quota is
        #  not enough.
        projectId = $CROSS.person.project.id
        serverUrl = $CROSS.settings.serverURL
        $http.get "#{serverUrl}/cinder/os-quota-sets/#{projectId}?usage=true"
          .success (quota) ->
            if quota.volumes['in_use'] >= quota.volumes['limit']
              toastr.error _(["Sorry, you have no more quota to get new %s",\
                _ "volumes"])
              $state.go "project.volume"
            else
              $createModal.clearLoading()
          .error (err) ->
            console.log err

class VolumeCreateModal extends $cross.Modal
  title: "Create Volume"
  slug: "volume_create"
  single: true
  modalLoading: true

  fields: ->
    [{
      slug: 'name'
      label: _("Name")
      tag: 'input'
      restrictions:
        required: true
        len: [1, 32]
    }, {
      slug: 'size'
      label: _("Size(GB)")
      tag: 'input'
      restrictions:
        required: true
        number: true
        len: [1, 4]
    }, {
      slug: 'type'
      label: _("Performance Type")
      tag: 'select'
      default: [{}]
    }, {
      slug: 'description'
      label: _("Description")
      tag: 'textarea'
      restrictions:
        required: false
        len: [0, 512]
    }, {
      slug: 'source'
      label: _("Boot source")
      tag: 'select'
      default: [{
        text: _("Empty volume")
        value: 'empty'
      }, {
        text: _("Volume")
        value: 'volume'
      }, {
        text: _("Volume snapshot")
        value: 'snapshot'
      }]
    }, {
      slug: 'image'
      label: _("Image")
      tag: 'select'
      type: 'hidden'
      restrictions:
        required: true
      default: []
    }]

  validator: ($scope, options) ->
    field = options.field
    source = $scope.form['source']
    if field == 'source' and source != 'empty'
      if $scope.modal.source
        defaultImg = $scope.modal.source[source]
        if not defaultImg.length
          defaultImg.push {text: _("No available"), value: -1}
        $scope.modal.fields[5].default = defaultImg
        $scope.modal.fields[5].type = ''
        if source == 'image'
          images = []
          for item in $scope.modal.source.image
            images.push item.value
          if $scope.form['image'] not in images
            $scope.form['image'] = defaultImg[0].value
          $scope.modal.fields[5].label = _('Image')
        else if source == 'volume'
          volumes = []
          for item in $scope.modal.source.volume
            volumes.push item.value
          if $scope.form['image'] not in volumes
            $scope.form['image'] = defaultImg[0].value
          $scope.modal.fields[5].label = _('Volume')
        else if source == 'snapshot'
          snapshots = []
          for item in $scope.modal.source.snapshot
            snapshots.push item.value
          if $scope.form['image'] not in snapshots
            $scope.form['image'] = defaultImg[0].value
          $scope.modal.fields[5].label = _('Volume snapshot')
      else
        $scope.modal.fields[5].type = 'hidden'

    else if field == 'source' and source == 'empty'
      $scope.modal.fields[5].type = 'hidden'
    super($scope, options)

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    serverUrl = $CROSS.settings.serverURL
    form = $scope.form
    quota = $scope.quota
    avaVol = quota.gigabytes.limit - quota.gigabytes.in_use
    sourceSize = $scope.sourceSize
    size = parseInt form['size']
    person = $CROSS.person
    data =
      size: size
      display_name: form['name']
      display_description: form['description']
      status: 'creating'
      attach_status: "detached"
      project_id: person.project.id
      user_id: person.user.id
      volume_type: form['type']
    if size > avaVol
      $scope.tips['size'] = _("Volume size should be less than") + avaVol
      options.callback false
      return
    if form['image'] == -1
      $scope.tips['image'] = _('Cannot be empty.')
      options.callback false
      return
    source = form['source']
    sorSize = sourceSize["#{source}_#{form['image']}"]
    if sorSize > size
      $scope.tips['size'] = _(["Volume size is smaller than image size %s", sorSize])
      options.callback false
      return
    if source == 'image'
      data['imageRef'] = form['image']
    else if source == 'snapshot'
      data['snapshot_id'] = form['image']
    else if source == 'volume'
      data['source_volid'] = form['image']
    $http.post "#{serverUrl}/volumes", data
      .success (vol) ->
        message =
          object: "volume-#{vol.id}"
          priority: 'info'
          loading: true
          content: _(['Volume %s is %s ...', data['display_name'], _('creating')])
        options.$gossipService.receiveMessage message
        options.callback false
        $state.go "project.volume", null, {reload: true}
      .error (error)->
        toastr.error _("Failed to create volume.")
        options.callback false
