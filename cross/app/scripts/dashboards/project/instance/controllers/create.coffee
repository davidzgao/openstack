'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module('Cross.project.instance')
  .controller 'project.instance.InstanceCreateCtr', ($scope, $http, $window, $q,
    $state, $gossipService, randomName) ->
    $scope.use_vlan = $window.$CROSS.settings.use_vlan
    $scope.useVolumeType = $window.$CROSS.settings.useVolumeType
    serverUrl = $window.$CROSS.settings.serverURL
    $scope.note =
      empty: _("Not input")
      modal:
        filter: _("Filters")
        advOptions: _ "Advanced Options"
        login: _ "Credentials"
        secretKey: _ "Keypair"
        password: _ "Password"
        defaultNetwork: _ "Default network"
      desc:
        image: _("Image")
        vcpu: _("CPU(Core)")
        ram: _("Ram(GB)")
        disk: _("Disk(GB)")
        instance: _("Instance")
        number: _("Number")
        name: _("Name")
        config: _("Configuration")
        usage: _("Quota usage")
      diskDefault: _("Default")
      create: _("Create")
      selfDefine: _("Custom root disk")
      keyPaireEmpty: _("No key pair available")

    $scope.modal =
      isDiskDefault: true
      imagePass: undefined
      useSnapshot: false
      passwordTip: undefined

    $scope.selectSource = (slug) ->
      $scope.modal.selectedSource = slug
      $scope.modal.selectedSub = 'all'
      images = $scope.modal.steps[0].fields[0].default
      $scope.note.imageEmpty = ""
      if slug == 'image'
        $scope.modal.passwordTip = undefined
        if not images[0].images.length
          $scope.note.imageEmpty = _("No resource available, ")
          $scope.modal.createUrl = "#/project/image/create"
        else
          $scope.imageClick(images[0].images[0])
      else if slug == 'snapshot'
        $scope.modal.passwordTip = _ "Its initial value is the snapshot's password which you had chose."
        $scope.modal.useSnapshot = true
        if not images[1].images.length
          $scope.note.imageEmpty = _("No resource available.")
          $scope.modal.createUrl = ""
        else
          $scope.imageClick(images[1].images[0])
      else if slug == 'volume'
        $scope.modal.passwordTip = undefined
        if not images[2].images.length
          $scope.note.imageEmpty = _("No resource available, ")
          $scope.modal.createUrl = "#/project/volume/create"
        else
          $scope.imageClick(images[2].images[0])

    $scope.selectSub = (subType) ->
      $scope.modal.selectedSub = subType
      slug = $scope.modal.selectedSource
      $scope.note.imageEmpty = ""
      $scope.modal.createUrl = ""
      images = $scope.modal.steps[0].fields[0].default
      index = 0
      if slug == 'snapshot'
        index = 1
      else if slug == 'volume'
        index = 2
      isEmpty = true
      for img in images[index].images
        if img.subType == subType
          isEmpty = false
          break

      if isEmpty
        $scope.note.imageEmpty = _("No resource available.")

    ###
    # Use default or custom root disk.
    ###
    $scope.diskChange = ->
      if $scope.modal.isDiskDefault
        $scope.modal.isDiskDefault = false
        $scope.form['flavor']['disk'] = $scope.diskQuota
        $scope.note.selfDefine = _("Use default")
      else
        $scope.modal.isDiskDefault = true
        $scope.form['flavor']['disk'] = 0
        $scope.note.selfDefine = _("Custom root disk")

    $insCreateModal = new InstanceCreateModal()
    $insCreateModal.initial($scope, {
      $http: $http
      $q: $q
      $window: $window
      $state: $state
      $gossipService: $gossipService
      $randomName: randomName
    })
    queryOpts =
      params:
        all_tenants: true
        is_public: 'true'
    # NOTE(ZhengYue): Hidden security_group field when use vmware
    hypervisor_type = $CROSS.settings.hypervisor_type
    if hypervisor_type == 'VMWARE'
      $scope.modal.steps[3]['fields'][2].type = 'hidden'

    publicImageHttp = $http.get "#{serverUrl}/images", queryOpts
    privateImageHttp = $http.get "#{serverUrl}/images"
    bootVolumeHttp = $http.get "#{serverUrl}/volumes?bootable=true"
    volumeSnapHttp = $http.get "#{serverUrl}/cinder/snapshots"
    volTypeHttp = $http.get "#{serverUrl}/volume_types"
    $q.all [publicImageHttp, privateImageHttp, bootVolumeHttp, volumeSnapHttp, volTypeHttp]
      .then (res) ->
        publicImages = res[0].data.data
        privateImages = res[1].data.data
        bootVolumes = res[2].data.data
        volumeSnaps = res[3].data
        volTypes = res[4].data
        basicImgs = []
        snapshots = []
        volumes = []
        volumeType = []
        for image in publicImages
          if image['is_public'] == 'false' || image['is_public'] == false
            continue
          imageMinSize = image.size / (1024 * 1024 * 1024)
          imageMinSize = imageMinSize.toFixed(2)
          image.min_disk = imageMinSize if imageMinSize > parseFloat image.min_disk
          pro = JSON.parse image.properties
          item =
            name: unescape(image.name)
            id: image.id
            subType: 'public'
            minDisk: image.min_disk
            minRam: image.min_ram / 1024
            osType: pro.os_type
            type: 'image'
            password: pro.admin_pass || null
          if image.status != 'active'
            continue
          if pro and (pro.image_type == 'snapshot' || pro.image_type == 'backup')
            snapshots.push item
            continue
          basicImgs.push item

        for image in privateImages
          if image['is_public'] == 'true' or image['is_public'] == true\
          or image['container_format'] == null or image['container_format'] == 'null'
            continue
          pro = JSON.parse image.properties
          imageMinSize = image.size / (1024 * 1024 * 1024)
          imageMinSize = imageMinSize.toFixed(2)
          image.min_disk = imageMinSize if imageMinSize > parseFloat image.min_disk
          item =
            name: unescape(image.name)
            id: image.id
            subType: 'private'
            minDisk: image.min_disk
            minRam: image.min_ram / 1024
            osType: pro.os_type
            type: 'image'
            password: pro.admin_pass || null
          if image.status != 'active'
            continue
          if pro and (pro.image_type == 'snapshot' || pro.image_type == 'backup')
            snapshots.push item
            continue
          basicImgs.push item

        for vol in bootVolumes
          volImgMeta = JSON.parse vol.volume_image_metadata
          item =
            name: vol.display_name
            id: vol.id
            size: vol.size
            subType: 'bootVolume'
            minDisk: Number(volImgMeta.min_disk)
            minRam: volImgMeta.min_ram / 1024
            osType: volImgMeta.os_type
            image: 'volume'
          volumes.push item

        for snp in volumeSnaps
          for vol in volumes
            if vol.id == snp.volume_id
              snapshotName = /^snapshot for (.*)?$/.exec(snp.display_name)
              snapshotName = snapshotName[1] if snapshotName
              item =
                name: if snapshotName \
                      then snapshotName \
                      else snp.display_name
                id: snp.id
                subType: 'volumeSnapshot'
                minDisk: if vol.size > vol.minDisk \
                         then vol.size \
                         else vol.minDisk
                minRam: vol.minRam
                osType: vol.osType
                type: 'volume'
              volumes.push item
              break

        for volType in volTypes
          item =
            isActive: ''
            isDisable: ''
            text: volType.name
            value: volType.id
          volumeType.push item

        if $scope.useVolumeType == 'true'
          $scope.modal.steps[1].fields[4].default = volumeType

        $scope.modal.steps[0].fields[0].default = [{
          name: _("Image")
          slug: 'image'
          images: basicImgs
          subs: [{
            name: _("Public")
            type: 'public'
          }, {
            name: _("Private")
            type: 'private'
          }]
        }, {
          name: _("Snapshot")
          slug: 'snapshot'
          images: snapshots
        }]
        $scope.modal.selectedSource = 'image'
        $scope.modal.selectedSub = 'all'
        if basicImgs.length
          $scope.modal.selectedImage = basicImgs[0].id + '_image'
          $scope.form['image']['image'] = basicImgs[0]
      .catch (err) ->
        # TODO(Li Xipeng): Handle get image list error.
        console.log err, "Failed to get images."
      .finally ->
        # NOTE(Liu Haobo):
        # if the in use resource is less then the quota set
        #   continue create resource
        # else
        #   it will call a reminder to warn user that quota is
        #  not enough
        projectId = $CROSS.person.project.id
        serverUrl = $CROSS.settings.serverURL
        $http.get "#{serverUrl}/nova/os-quota-sets/#{projectId}?usage=true"
          .success (quota) ->
            if quota.instances['in_use'] >= quota.instances['limit']
              toastr.error _(["Sorry, you have no more quota to get new %s",\
                _ "instances"])
              $state.go "project.instance"
            else
              $insCreateModal.clearLoading()
          .error (err) ->
            console.log err

    $scope.vcpuClick = (item) ->
      if item.isDisable
        return
      val = item.value
      for item in $scope.modal.steps[1].fields[0].default
        if val == item.value
          item.isActive = 'active'
        else
          item.isActive = ''
      cores = $scope.quota.cores
      cores.used = cores.cUsed + (val * $scope.form['flavor']['number'])
      if angular.isNumber(cores.total)
        cores.usage = cores.used * 100 / cores.total
        cores.usage = parseInt cores.usage
      cores.usageStatus = if cores.usage > 100 then 'warn' else undefined
      $scope.quota.cores = cores
      $scope.form['flavor']['vcpus'] = val

    $scope.imageClick = (image) ->
      $scope.modal.imagePass = unescape image.password if image.password
      slug = $scope.modal.selectedSource
      $scope.modal.selectedImage = image.id + '_' + slug
      $scope.form['image']['image'] = image
      if $scope.quota
        cores = $scope.quota.cores
        ram = $scope.quota.ram
        instance = $scope.quota.instance
        isSet = false
        $scope.form['flavor']['vcpus'] = undefined
        for item in $scope.modal.steps[1].fields[0].default
          item.isActive = ''
          item.isDisable = ''
          if item.value > (cores.total - cores.cUsed)
            item.isDisable = 'disable'
          else if not isSet
            $scope.quota.cores.used = cores.cUsed + item.value
            $scope.form['flavor']['vcpus'] = item.value
            item.isActive = 'active'
            isSet = true
        isSet = false
        $scope.form['flavor']['ram'] = undefined
        for item in $scope.modal.steps[1].fields[1].default
          item.isActive = ''
          item.isDisable = ''
          if item.value > (ram.total - ram.cUsed)
            item.isDisable = 'disable'
          else if item.value < image.minRam
            item.isDisable = 'disable'
          else if not isSet
            $scope.form['flavor']['ram'] = item.value
            $scope.quota.ram.used = ram.cUsed + item.value
            item.isActive = 'active'
            isSet = true
        isSet = false
        $scope.modal.isDiskDefault = false
        $scope.form['flavor']['disk'] = 0
        for item in $scope.modal.steps[1].fields[2].default
          item.isActive = ''
          item.isDisable = ''
          if item.value < image.minDisk
            item.isDisable = 'disable'
          else if not isSet and image.minDisk
            $scope.diskQuota = item.value
            item.isActive = 'active'
            $scope.modal.isDiskDefault = true
            isSet = true
        isSet = false
        $scope.form['flavor']['type'] = undefined
        for item in $scope.modal.steps[1].fields[4].default
          if not isSet
            $scope.form['flavor']['type'] = item.value
            item.isActive = 'active'
            isSet = true
            break

        if cores.total <= cores.cUsed
          $scope.tips['flavor']['vcpus'] = _("Lack of CPU quota")
        if ram.total <= ram.cUsed
          $scope.tips['flavor']['ram'] = _("Lack of memory quota")
        if instance.total <= instance.cUsed
          $scope.tips['flavor']['number'] = _("Lack of instance quota")

    $scope.ramClick = (item) ->
      if item.isDisable
        return
      val = item.value
      for item in $scope.modal.steps[1].fields[1].default
        if val == item.value
          item.isActive = 'active'
        else
          item.isActive = ''
      ram = $scope.quota.ram
      ram.used = ram.cUsed + (val * $scope.form['flavor']['number'])
      if angular.isNumber(ram.total)
        ram.usage = ram.used * 100 / ram.total
        ram.usage = parseInt ram.usage
      ram.usageStatus = if ram.usage > 100 then 'warn' else undefined
      $scope.quota.ram = ram
      $scope.form['flavor']['ram'] = val

    $scope.diskClick = (item) ->
      val = item.value
      if val < $scope.form.image.image.minDisk
        return

      for item in $scope.modal.steps[1].fields[2].default
        if val == item.value
          item.isActive = 'active'
        else
          item.isActive = ''
      $scope.form['flavor']['disk'] = val

    $scope.typeClick = (item) ->
      val = item.value

      for item in $scope.modal.steps[1].fields[4].default
        if val == item.value
          item.isActive = 'active'
        else
          item.isActive = ''
      $scope.form['flavor']['type'] = val

    $scope.selectedSubnet = {}
    selectedNetwork = []
    networkIdMatchSubnetId = {}
    subnetId = {}
    if $CROSS.settings.use_neutron == true
      $scope.useNeutron = true
    else
      $scope.useNeutron = false
    $scope.selectSubnet = (selectedSubnet) ->
      for net of $scope.subnetMap
        for subnet,index in $scope.subnetMap[net].subnets
          if selectedSubnet.network_id in selectedNetwork
            for item in $scope.subnetMap[selectedSubnet.network_id].subnets
              item.isActive = ''
            if subnet.id == selectedSubnet.id
              if networkIdMatchSubnetId[selectedSubnet.network_id][selectedSubnet.id]
                delete networkIdMatchSubnetId[selectedSubnet.network_id][selectedSubnet.id]
                subnet.isActive = ''
                delete $scope.selectedSubnet[selectedSubnet.network_id]
              else
                delete networkIdMatchSubnetId[selectedSubnet.network_id]
                subnetId[selectedSubnet.id] = selectedSubnet.id
                networkIdMatchSubnetId[selectedSubnet.network_id] = subnetId
                subnetId = {}
                subnet.isActive = 'active'
                $scope.selectedSubnet[selectedSubnet.network_id] = selectedSubnet
              return
          else
            if subnet.id == selectedSubnet.id
              subnetId[selectedSubnet.id] = selectedSubnet.id
              networkIdMatchSubnetId[selectedSubnet.network_id] = subnetId
              subnetId = {}
              subnet.isActive = 'active'
              $scope.selectedSubnet[selectedSubnet.network_id] = selectedSubnet
              selectedNetwork.push selectedSubnet.network_id
              return

    # NOTE(ZhengYue): Select network
    $scope.selectVlanNet = (netId) ->
      for net in $scope.defaultNets
        if net.id == netId
          if net.active
            if $scope.selected_vlan_nets == 1
              return
            net.active = ''
            $scope.subnetMap[netId].active = false
            $scope.selected_vlan_nets -= 1
          else
            net.active = 'active'
            $scope.subnetMap[netId].active = true
            $scope.selected_vlan_nets += 1
          break

    $scope.selectNetwork = ($index) ->
      clickedNetwork = $scope.modal.steps[2].fields[0].default[$index]
      isActive = clickedNetwork.isActive
      if isActive
        clickedNetwork.isActive = ''
        $scope.form['network']['network'][$index].checked = 0
        $scope.subnetMap[clickedNetwork.value].isSelected = false
        $scope.subnetMap[clickedNetwork.value].active = false
        if $scope.selectedFixedIps
          if $scope.selectedFixedIps[clickedNetwork.id]
            delete $scope.selectedFixedIps[clickedNetwork.id]
      else
        clickedNetwork.isActive = 'active'
        $scope.form['network']['network'][$index].checked = 1
        $scope.subnetMap[clickedNetwork.value].isSelected = true
        $scope.subnetMap[clickedNetwork.value].active = true

    $scope.$on 'ip-validate-result', (event, detail) ->
      if not detail
        $scope.tips['network']['ip_assign'] = $scope.noneFixedIPTips

    $scope.$on 'ip-confirmed', (event, detail) ->
      if $scope.ipAssignWay == 'assign'
        if not $scope.selectedFixedIps
          $scope.selectedFixedIps = {}
        $scope.selectedFixedIps[detail.network_id] = detail.fixed_ip
        $scope.noneSlectedFixedIp = false
      if not $scope.fixedIpCheck()
        $scope.tips['network']['ip_assign'] = $scope.noneFixedIPTips
      else
        $scope.tips['network']['ip_assign'] = undefined
    $scope.$on 'ip-canceled', (event, detail) ->
      if not $scope.selectedFixedIps
        $scope.selectedFixedIps = {}
      if $scope.selectedFixedIps[detail.network_id]
        delete $scope.selectedFixedIps[detail.network_id]
      if not $scope.fixedIpCheck()
        $scope.tips['network']['ip_assign'] = $scope.noneFixedIPTips
      else
        $scope.tips['network']['ip_assign'] = undefined

    $scope.changeCreden = (type) ->
      if type == 'password'
        $scope.modal.steps[3].fields[4].type = 'hidden'
        $scope.modal.steps[3].fields[5].type = 'input'
      else
        $scope.modal.steps[3].fields[5].type = 'hidden'
        $scope.modal.steps[3].fields[4].type = 'select'
      $scope.modal.credential = type

    $scope.passwordToText = (event) ->
      target = $(event.currentTarget)
      passwordField = target.siblings('input')
      if passwordField.attr('type') == 'password'
        passwordField.attr('type', 'text')
        target.removeClass('glyphicon-eye-close')
        target.addClass('glyphicon-eye-open')
      else
        passwordField.attr('type', 'password')
        target.removeClass('glyphicon-eye-open')
        target.addClass('glyphicon-eye-close')
      return


class InstanceCreateModal extends $cross.Modal
  title: "Create Instance"
  slug: "instance_create"
  single: false
  steps: ['image', 'flavor', 'network', 'basic']
  modalLoading: true

  step_image: ->
    name: _ "Select image"
    fields: [{
      slug: "image"
      label: _ "Boot source"
      tag: "select"
      default: []
    }, {
      slug: "with_delete"
      label: _ "Delete volume when delete instance"
      tag: "checkbox"
      default: false
    }]

  step_flavor: ->
    settings = $CROSS.settings
    VCPUs = [1, 2, 4, 8, 12, 16]
    if settings.instance_create_vcpu_range
      VCPUs = settings.instance_create_vcpu_range
    vcpuDefault = []
    for vcpu in VCPUs
      vcpuDefault.push {
        value: vcpu
        isActive: ''
        isDisable: ''}
    RAM = [0.5, 1, 2, 4, 8, 12, 16, 24, 32]
    if settings.instance_create_ram_range
      RAM = settings.instance_create_ram_range
    ramDefault = []
    for ram in RAM
      ramDefault.push {
        value: ram
        isActive: ''
        isDisable: ''}
    DISK = [10, 20, 40, 80, 100, 120, 200, 320, 500]
    if settings.instance_create_disk_range
      DISK = settings.instance_create_disk_range
    diskDefault = []
    for disk in DISK
      diskDefault.push {
        value: disk
        isActive: ''
        isDisable: ''}
    name: _("Select flavor")
    fields: [{
      slug: "vcpus"
      label: _ "CPU(Core)"
      default: vcpuDefault
    }, {
      slug: "ram"
      label: _ "Ram(GB)"
      default: ramDefault
    }, {
      slug: "disk"
      label: _ "Disk(GB)"
      default: diskDefault
    }, {
      slug: "number"
      label: _ "Number"
      tag: "input"
      type: 'text'
      restrictions:
        required: true
        number: true
        len: [1, 3]
    }, {
      slug: "type"
      label: _ "Type"
      default: []
    }]

  step_network: ->
    name: _ "Select network"
    fields: [{
      slug: "network"
      label: _ "Basic network"
      default: []
    }, {
      slug: "ip_assign"
      label: _ "IP Assign"
      tag: "select"
      default: []
    }, {
      slug: "subnet"
      label: _ "Subnet"
      default: []
    }]

  step_basic: ->
    passReg = ///[-\da-zA-Z`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]*
                 ((\d+[a-zA-Z]+[-`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]+)
                 |(\d+[-`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]+[a-zA-Z]+)
                 |([a-zA-Z]+\d+[-`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]+)
                 |([a-zA-Z]+[-`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]+\d+)
                 |([-`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]+\d+[a-zA-Z]+)
                 |([-`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]+[a-zA-Z]+\d+))
                 [-\da-zA-Z`=\\\[\];',./~!@#$%^&*()_+|{}:"<>?]*///
    name: _ "Basic info"
    fields: [{
      slug: "name"
      label: _ "Name"
      tag: "input"
      restrictions:
        required: true
        len: [1, 25]
    }, {
      slug: "cluster"
      label: _ "Cluster"
      tag: "select"
      default: []
      restrictions:
        required: false
        len: [1, 25]
    }, {
      slug: "security_group"
      label: _ "Security group"
      tag: "input"
      type: 'checkbox-list'
      default: []
    }, {
      slug: "username"
      label: _ "Username"
      tag: "input"
      default: 'root'
    }, {
      slug: "secret_key"
      label: _ "Secret key"
      tag: "select"
      default: []
      restrictions:
        func: (scope, val)->
          if val == undefined or val == ""
            return _("No key pair available")
    }, {
      slug: "password"
      label: _ "Admin pass"
      tag: "input"
      type: 'password'
      restrictions:
        required: true
        len: [6, 18]
        regex: [passReg,
          _("Must and only consist with special character, alphabet, number")]
    }, {
      slug: 'custom'
      label: _ ("Custom script")
      tag: 'textarea'
      type: 'hidden'
    }]

  validator: ($scope, options) ->
    step = options.step
    field = options.field
    if step == 'flavor' and field == 'number'
      val = $scope.form[step][field]
      cores = $scope.quota.cores
      ram = $scope.quota.ram
      instance = $scope.quota.instance
      volumes = $scope.quota.volumes
      cores.used = cores.cUsed + \
                   ($scope.form['flavor']['vcpus'] * Number(val))
      ram.used = ram.cUsed + \
                 ($scope.form['flavor']['ram'] * Number(val))
      volumes.used = volumes.cUsed + Number(val)
      instance.used = instance.cUsed + Number(val)
      if val > instance.total - instance.cUsed
        instance.used = instance.total
        $scope.form[step][field] = instance.max
      if val == null \
      or val == undefined \
      or not /^[1-9][0-9]*$/.test(val)
        instance.used = instance.cUsed + 1
        $scope.form[step][field] = 1
      if angular.isNumber cores.total
        cores.usage = cores.used * 100 / cores.total
        cores.usage = parseInt cores.usage
        if cores.usage > 100
          toastr.error _ "CPU quota is not enough!"
          cores.usageStatus = 'warn'
        else
          cores.usageStatus = undefined
      if angular.isNumber ram.total
        ram.usage = ram.used * 100 / ram.total
        ram.usage = parseInt ram.usage
        if ram.usage > 100
          toastr.error _ "Ram quota is not enough!"
          ram.usageStatus = 'warn'
        else
          ram.usageStatus = undefined
      if angular.isNumber instance.total
        instance.usage = instance.used * 100 / instance.total
        instance.usage = parseInt instance.usage
      if angular.isNumber volumes.total
        volumes.usage = volumes.used * 100 / volumes.total
        volumes.usage = parseInt volumes.usage
        if volumes.usage > 100
          toastr.error _ "Volume quota is not enough!"
          volumes.usageStatus = 'warn'
        else
          volumes.usageStatus = undefined
      ipAssigns = $scope.modal.steps[2].fields[1].default
      if Number(val) > 1
        if ipAssigns.length > 0
          ipAssigns[1].available = false
          $scope.ipAssignChange(0)
      else
        if ipAssigns.length > 0
          ipAssigns[1].available = true
    else
      rs = super($scope, options)
      if not rs
        return false
    return true

  nextStep: ($scope, options, callback) ->
    $http = options.$http
    $window = options.$window
    $q = options.$q
    serverUrl = $window.$CROSS.settings.serverURL
    if $scope.modal.stepIndex == 0
      if $scope.modal.steps[1].loaded
        callback true
        return
      $http.get "#{serverUrl}/auth"
        .success (userData) ->
          projectId = userData.project.id
          cinderQuotaHttp = $http.get "#{serverUrl}/cinder/os-quota-sets/#{projectId}?usage=true"
          novaQuotaHttp = $http.get "#{serverUrl}/nova/os-quota-sets/#{projectId}?usage=true"
          $q.all [cinderQuotaHttp, novaQuotaHttp]
            .then (values) ->
              quota = values[1].data
              cinderQuota = values[0].data
              max = $CROSS.settings.MAX_INSTANCES_ON_CREATING || 1000
              volumes =
                used: cinderQuota.volumes.in_use
                cUsed: cinderQuota.volumes.in_use
                total: cinderQuota.volumes.limit
                usage: 0

              cores =
                used: quota.cores.in_use
                cUsed: quota.cores.in_use
                total: quota.cores.limit
                usage: 0

              instance =
                used: quota.instances.in_use
                cUsed: quota.instances.in_use
                total: quota.instances.limit
                usage: 0
              if instance.total == -1
                instance.total = _("Unlimited")
                $scope.form['flavor']['number'] = 1
                instance.used = instance.cUsed + 1
              else if instance.total != 0
                $scope.form['flavor']['number'] = 1
                instance.used = instance.cUsed + 1
              if angular.isNumber instance.total
                instance.usage = instance.used * 100 / instance.total
                instance.usage = parseInt instance.usage
                max = instance.total - instance.cUsed
              instance.max = max

              ram =
                used: quota.ram.in_use
                cUsed: quota.ram.in_use
                total: quota.ram.limit
                usage: 0
              if ram.total > 0
                ram.total = ram.total / 1024
              ram.used = parseInt ram.used / 1024
              ram.cUsed = parseFloat ram.cUsed / 1024

              image = $scope.form['image']['image']
              isSet = false
              for item in $scope.modal.steps[1].fields[0].default
                if item.value > (cores.total - cores.used)
                  item.isDisable = 'disable'
                else if not isSet
                  $scope.form['flavor']['vcpus'] = item.value
                  cores.used = cores.cUsed + item.value
                  item.isActive = 'active'
                  isSet = true
              if cores.total != -1 and cores.total
                cores.usage = cores.used * 100 / cores.total
                cores.usage = parseInt cores.usage
              else if cores.total == -1
                cores.total = _("Unlimited")

              isSet = false
              for item in $scope.modal.steps[1].fields[1].default
                if item.value > (ram.total - ram.used)
                  item.isDisable = 'disable'
                else if item.value < image.minRam
                  item.isDisable = 'disable'
                else if not isSet
                  $scope.form['flavor']['ram'] = item.value
                  ram.used = ram.cUsed + item.value
                  item.isActive = 'active'
                  isSet = true
              if ram.total != -1 and ram.total
                ram.usage = ram.used * 100 / ram.total
                ram.usage = parseInt ram.usage
              else if ram.total == -1
                ram.total = _("Unlimited")

              $scope.form['flavor']['disk'] = 0
              isSet = false
              for item in $scope.modal.steps[1].fields[2].default
                if item.value < image.minDisk
                  item.isDisable = 'disable'
                else if not isSet and image.minDisk
                  $scope.diskQuota = item.value
                  item.isActive = 'active'
                  $scope.modal.isDiskDefault = true
                  isSet = true

              $scope.form['flavor']['type'] = undefined
              isSet = false
              for item in $scope.modal.steps[1].fields[4].default
                if not isSet
                  $scope.form['flavor']['type'] = item.value
                  item.isActive = 'active'
                  isSet = true
              $scope.modal.steps[1].loaded = true
              $scope.quota =
                cores: cores
                ram: ram
                instance: instance
                volumes: volumes
              if cores.total < cores.used
                $scope.tips['flavor']['vcpus'] = _("Lack of CPU quota")
              if ram.total < ram.used
                $scope.tips['flavor']['ram'] = _("Lack of memory quota")
              if instance.total < instance.used
                $scope.tips['flavor']['number'] = _("Lack of instance quota")
              callback true
            .catch (err) ->
              console.log "Error: ", err
              $scope.modal.steps[1].loaded = false
              callback false
        .error (err) ->
          $scope.modal.steps[1].loaded = false
          console.log "User data error:", err
          callback false
    else if $scope.modal.stepIndex == 1
      if $scope.quota.cores.usageStatus == 'warn'\
      or $scope.quota.ram.usageStatus == 'warn'\
      or $scope.quota.volumes.usageStatus == 'warn'
        callback false
        return
      if $scope.modal.steps[2].loaded
        callback true
        return
      if $CROSS.settings.use_neutron
        queryOpts =
          'router:external': false
      else
        queryOpts = {}
      getRange = (nets) ->
        rangeMap = {}
        for net in nets
          rangeMap[net.id] = {
            subnets: [net]
            name: net.label
            active: false
          }
        return rangeMap
      $cross.networks.listNetworks $http, queryOpts, (err, nets) ->
        if err
          $scope.modal.steps[2].loaded = false
          callback false
          return
        avai = []
        formNets = []
        if nets.subnets
          subnets = nets.subnets
          networks = nets.networks
        else
          networks = nets
          subnets = getRange(networks)
        $scope.defaultNets = []
        currentProject = $CROSS.person.project.id
        for net in networks
          if not net.subnets or not net.subnets.length
            if net.project_id
              if net.project_id == currentProject
                $scope.defaultNets.push net
              else if net.project_id == 'null'
                $scope.defaultNets.push net
              else
                continue
            else
              $scope.defaultNets.push net
              continue
          else
            $scope.defaultNets.push net
          formNets.push {id: net.id, checked: 0}
          item =
            text: "#{net.name or net.label}(#{net.id})"
            value: net.id
            isActive: ''
          avai.push item
        $scope.selected_vlan_nets = 0
        if $scope.defaultNets.length > 0
          first_id = $scope.defaultNets[0].id
          $scope.defaultNets[0].active = 'active'
          if not $CROSS.settings.use_neutron
            subnets = getRange($scope.defaultNets)
          subnets[first_id].active = true
          $scope.selected_vlan_nets = 1
        if not $scope.defaultNets.length and not avai.length
          $scope.none_available_nets = true
          $scope.tips['network']['network'] = _('No available networks')
        if avai.length
          avai[0].isActive = 'active'
          formNets[0].checked = 1
          if subnets
            subnets[avai[0].value].isSelected = true
        $scope.modal.steps[2].fields[0].default = avai

        $scope.fixedIpCheck = () ->
          isEmptyObject = (obj) ->
            if not obj
              return true
            for name of obj
              return false
            return true

          formNet = $scope.form['network']
          selectedNets = 0
          for net in formNet['network']
            if net.checked == 1
              selectedNets += 1
          if selectedNets > 0 and formNet.ip_assign == 'assign'
            if $scope.selectedFixedIps
              if isEmptyObject($scope.selectedFixedIps)
                $scope.noneSlectedFixedIp = true
                return false
              else
                $scope.noneSlectedFixedIp = false
                return true
            else
              $scope.noneSlectedFixedIp = true
              return false
          else
            return true

        $scope.noneFixedIPTips = _ 'Please select one fixed ip, or use auto assign.'
        $scope.noneRandomRangeIPTips = _ 'You can selected which subnet to get random floating ip or yet.'
        $scope.ipAssignChange = (sourceIndex) ->
          ipAssignWays = $scope.modal.steps[2].fields[1].default
          for way in ipAssignWays
            way.selected = false
          ipAssignWays[sourceIndex].selected = true
          $scope.ipAssignWay = ipAssignWays[sourceIndex].slug
          $scope.form['network']['ip_assign'] = $scope.ipAssignWay
          if not $scope.fixedIpCheck()
            $scope.tips['network']['ip_assign'] = $scope.noneFixedIPTips
          else
            $scope.tips['network']['ip_assign'] = undefined

        $scope.subnetMap = subnets
        if $scope.form.flavor.number > 1
          $scope.modal.steps[2].fields[1].default = [{
            name: _("Auto")
            slug: 'auto'
            selected: true
            available: true
          }, {
            name: _("Assign")
            slug: 'assign'
            sets: subnets
            available: false
          }]
        else
          $scope.modal.steps[2].fields[1].default = [{
            name: _("Auto")
            slug: 'auto'
            selected: true
            available: true
          }, {
            name: _("Assign")
            slug: 'assign'
            sets: subnets
            available: true
          }]
        $scope.ipAssignWay = 'auto'
        $scope.form['network']['ip_assign'] = 'auto'

        $scope.form['network']['network'] = formNets
        $scope.modal.steps[2].loaded = true
        callback true
    else if $scope.modal.stepIndex == 2
      if $scope.modal.useSnapshot and $scope.modal.imagePass
        $scope.form['basic']['password'] = $scope.modal.imagePass
      $scope.modal.credential = 'secret_key'
      $scope.modal.steps[3].fields[5].type = 'hidden'
      $scope.modal.steps[3].fields[4].type = 'select'
      if $scope.form.image.image.osType == 'windows'
        $scope.modal.steps[3].fields[4].type = 'hidden'
        $scope.modal.steps[3].fields[5].type = 'input'
        $scope.modal.credential = 'password'
      if $scope.modal.steps[3].loaded
        callback true
        return
      hash = 'os-security-groups'
      secGrpHttp = $http.get "#{serverUrl}/#{hash}"
      clusterHttp = $http.get "#{serverUrl}/os-availability-zone"
      keypairHttp = $http.get "#{serverUrl}/os-keypairs"

      $q.all [secGrpHttp, keypairHttp, clusterHttp]
        .then (res) ->
          securityGroups = res[0].data
          keypairs = res[1].data
          clusters = res[2].data
          avai = []
          for sec in securityGroups
            item =
              text: sec.name
              value: sec.name
            avai.push item
          $scope.modal.steps[3].fields[2].default = avai
          if avai.length
            $scope.form['basic']['security_group'] = [avai[0].value]
          zooms = [{text: _('Default'), value: -1}]
          for zm in clusters
            item =
              text: zm.zoneName
              value: zm.zoneName
            zooms.push item
          $scope.modal.steps[3].fields[1].default = zooms
          $scope.form['basic']['cluster'] = zooms[0].value
          pairs = []
          for pair in keypairs
            item =
              text: pair.name
              value: pair.name
            pairs.push item
          if pairs.length
            $scope.modal.steps[3].fields[4].default = pairs
            $scope.form['basic']['secret_key'] = pairs[0].value
          image = $scope.form['image']['image']
          $scope.form['basic']['username'] = 'root'
          if image.osType and image.osType == 'windows'
            $scope.form['basic']['username'] = 'Administrator'
          $scope.modal.steps[3].loaded = true
          callback true
        .catch (err) ->
          callback false
          $scope.modal.steps[3].loaded = false
    else
      callback false

  handle: ($scope, options)->
    $window = options.$window
    $http = options.$http
    $state = options.$state
    $randomName = options.$randomName
    form = $scope.form
    serverUrl = $CROSS.settings.serverURL
    projectId = $CROSS.person.project.id
    userId = $CROSS.person.user.id
    opts =
      params:
        ram: form['flavor']['ram'] * 1024
        disk: form['flavor']['disk']
        vcpus: form['flavor']['vcpus']
      $http: $http
      $window: $window
    $cross.nova.createFlavor opts, (err, flavor) ->
      if not err
        image = form['image']['image']
        responseUrl = '/servers'
        imageRef = undefined
        dev_mapping_v2 = undefined
        availability_zone = undefined
        if image.type == 'image'\
        and not $CROSS.settings.boot_from_volume
          imageRef = image.id
        else
          dev_mapping_v2 = [{
            source_type: "image"
            delete_on_termination: true
            boot_index: 0
            uuid: image.id
            destination_type: "volume"
            volume_size: if form['flavor']['disk'] then form['flavor']['disk'] else $scope.diskQuota
          }]
        data =
          server:
            name: form['basic']['name']
            imageRef: imageRef
            flavorRef: flavor.id
            block_device_mapping_v2: dev_mapping_v2
        # metadata
        meta =
          os_type: image.osType
        # Keypair & metadata
        data['server']['user_data'] = ""
        data['server']['metadata'] = meta
        if $scope.modal.credential=='password'
          pass = form['basic']['password']
          meta['admin_pass'] = pass
          meta['admin_username'] = form['basic']['username']
          if meta['os_type'] == 'linux' or not meta['os_type']
            CLOUD_INIT_USER_DATA = "#cloud-config" +\
                    "\ndisable_root: False" +\
                    "\npassword: %s" +\
                    "\nchpasswd:" +\
                    "\n    list: |" +\
                    "\n        root:%s" +\
                    "\n    expire: False" +\
                    "\nssh_pwauth: True"
            cIinitData = CLOUD_INIT_USER_DATA.replace /\%s/g, pass
            data['server']['user_data'] = cIinitData
        else
          secretKey = form['basic']['secret_key']
          if secretKey
            data['server']['key_name'] = secretKey
        # boot volume type and name
        if form['flavor']['type']
          data['server']['metadata']['volume_type'] = form['flavor']['type']
        data['server']['metadata']['volume_name'] = form['basic']['name'] + "--boot_volume"
        # availability zone
        cluster = form['basic']['cluster']
        if cluster != -1
          availability_zone = cluster
        if availability_zone != undefined
          data['server']['availability_zone'] = availability_zone
        # max count & min count
        count = form['flavor']['number']
        data['server']['min_count'] = count
        data['server']['max_count'] = count
        # security group
        secNames = []
        for sec in form['basic']['security_group']
          secNames.push {name: sec}
        if secNames.length
          data['server']['security_groups'] = secNames
        hypervisor_type = $CROSS.settings.hypervisor_type
        if hypervisor_type == 'VMWARE'
          data['server']['security_groups'] = []
        # networks
        nics = []
        ipAssign = form['network']['ip_assign']
        if ipAssign == 'assign'
          if not $CROSS.settings.use_neutron
            for net in $scope.form['network']['network']
              if net.checked
                nics.push {
                  'uuid': net.id
                  'fixed_ip': $scope.selectedFixedIps[net.id]
                }
            data['server']['version'] = 2
          else
            for nic in form['network']['network']
              if nic.checked
                if $scope.selectedFixedIps[nic.id]
                  nics.push {
                    uuid: nic.id
                    fixed_ip: $scope.selectedFixedIps[nic.id]
                  }
                else
                  nics.push {uuid: nic.id}
        else
          if not $CROSS.settings.use_neutron
            for net in form['network']['network']
              if net.checked
                nics.push {
                  'uuid': net.id
                }
          else
            for nic in form['network']['network']
              subnet_support = {}
              if nic.checked
                for networkId of $scope.selectedSubnet
                  if nic.id == networkId
                    nics.push {
                      uuid: nic.id
                    }
                    # FIXME(Li Xipeng): As nova api not support subnet for instance
                    # booting any more, not set subnet_id item at nic any more
                    # add network and subnet id mapping at subnet_support, this
                    # will support creating instance with subnet.
                    subnet_support[nic.id] = $scope.selectedSubnet[networkId].id
                data['server']['metadata']['SUPPORT:subnet'] = JSON.stringify(subnet_support)
                if not nics.length
                  nics.push {uuid: nic.id}
        if nics.length
          data['server']['networks'] = nics
        userData = form['basic']['custom']
        if userData
          data["server"]["user_data"] += userData
        $http.post "#{serverUrl}#{responseUrl}", data['server']
          .success (server) ->
            toastr.success _("Successfully post instances creating task, please wait ...")
            options.callback true
          .error (err) ->
            HANDLE_MSG =
              smallDisk: "Instance type's disk is too small for requested image."
              smallFlavor: "Flavor's disk is too small for requested image."

            msg = _ "Failed to create server"
            if err.status == 400
              if err.message == HANDLE_MSG.smallDisk or err.message == HANDLE_MSG.smallFlavor
                msg = _ err.message
            toastr.error msg
            options.callback false
