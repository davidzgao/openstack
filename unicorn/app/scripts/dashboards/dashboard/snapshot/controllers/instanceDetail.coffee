angular.module("Unicorn.dashboard.snapshot")
  .controller "dashboard.snapshot.instanceSnapDetailCtr", ($scope, $http,
  $q, $window, $state, $stateParams) ->
    $scope.detail_tabs = [
      {
        name: _('Overview'),
        url: 'dashboard.snapshot.instanceSnapId.overview1',
        available: true
      }
    ]
    $scope.currentId = $stateParams.instanceSnapId
    volumeSnapDetail = new $unicorn.DetailView()
    volumeSnapDetail.init($scope, {
      $stateParams: $stateParams
      $state: $state
      itemId: $scope.currentId
    })
  .controller 'dashboard.snapshot.instanceSnapOverviewCtr', ($scope,
  $http, $window, $state, $stateParams, $updateResource) ->
    $scope.$emit('tabDetail', 'instance.snapshot.html')
    $scope.currentId = $stateParams.instanceSnapId
    $scope.note =
      detail:
        advanceConfig: _("Advance config")
        add: _("Add properties")
        save: _("Save")
        edit: _("Edit")
        cancel: _("Cancel")
        info: _("Image Detail")
        id: _("ID")
        name: _("Name")
        status: _("Status")
        type: _("Type")
        host: _("Host")
        project: _("Project")
        description: _("Description")
        size: _("Size")
        created_at: _("Created")
        is_public: _("Is public")
        disk_format: _("Disk format")
        container_format: _("Container format")
        username: _("User Name")
        password: _("Password")
        osType: _("OS type")
        min_ram: _("Min ram(MB)")
        min_disk: _("Min disk(GB)")
        config: _("Configuration")
        propertiesEmpty: _("no properties")

    osTypes = [{
      text: _("windows")
      value: 'windows'
    }, {
      text: _("linux")
      value: 'linux'
    }]
    if $window.$UNICORN.settings.osTypes
      osTypes = []
      for os in $window.$UNICORN.settings.osTypes
        item =
          text: os
          value: os
        osTypes.push item

    $scope.osDefault = osTypes

    initial = (image) ->
      image.status = _(image.status)
      image.is_public = if image.is_public then _("Public") else _("Private")
      image.size = $unicorn.utils.getByteFix image.size
      $scope.image = image
      if typeof image.properties == 'string'
        image.properties = JSON.parse image.properties
      extProperties = {}
      $scope.modal =
        defineKey: ""
        defineValue: ""
        name: image.name
        minRam: image.min_ram
        minDisk: image.min_disk

      if image.properties.username != undefined
        $scope.modal.username = image.properties.username
      if image.properties.password != undefined
        $scope.modal.password = image.properties.password
      if image.properties.description != undefined
        $scope.modal.description = image.properties.description
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
        if key == 'username' || key == 'password' || key == 'description' || key == 'os_type'
          continue
        if image.properties[key] == null
          extProperties[key] = undefined
        else if typeof image.properties[key] != 'string'
          extProperties[key] = JSON.stringify image.properties[key]
        else
          extProperties[key] = image.properties[key]
      $scope.modal.properties = {}
      $scope.modal.showExtpro = false
      if Object.keys(extProperties).length
        $scope.modal.showExtpro = true

    # Get server detail info and judge action set for instance
    serverUrl = $window.$UNICORN.settings.serverURL
    getImage = () ->
      $http.get "#{serverUrl}/images/#{$scope.currentId}"
        .success (image) ->
          if image.owner != $window.$UNICORN.person.project.id
            $scope.editDisabled = true
          initial image
        .error (err) ->
          toastr.error _("Failed to get image detail.")

    getImage()

    validKeyOrValue = (val, isKey) ->
      if (val == undefined or val == "") and isKey
        #$scope.tips['properties']['self_define'] = _("Key could not be empty")
        return
      if isKey
        if $scope.modal.properties[val] != undefined
          #$scope.tips['properties']['self_define'] = _("Key is already exist.")
          return
      if val.length > 32
        #$scope.tips["properties"]['self_define'] = _("Length must be shorter than 33")
        return
      #$scope.tips["others"]['self_define'] = ""
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

    $scope.detailKeySet = {
      detail: [
        base_info:
          title: _("Image Detail")
          keys: [
            {
              key: 'name'
              value: _("Name")
              editable: true
              restrictions:
                required: true
                len: [4, 25]
              editAction: (key, value) ->
                $updateResource $scope, key, value, 'backup'
                return
            },
            {
              key: 'id'
              value: _("ID")
            },
            {
              key: 'size'
              value: _("Size")
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
