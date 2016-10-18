'use strict'

angular.module('Cross.project.instance')
  .controller 'project.instance.InstanceActionCtrl', ($scope, $http, $window) ->
    $scope.serverAction = (instanceId, action) ->
      $cross.instanceAction action, $http, $window, instanceId, (status) ->
        console.log "Action error:", status

  .controller 'project.instance.DetachVolumeCtrl', ($scope, $http,
  $window, $q, $stateParams, $state, $gossipService) ->
    $detachModal = new DetachVolumeModal()
    $detachModal.initial($scope, {
      $state: $state
      $http: $http,
      instanceId: $stateParams.instId
      $window: $window
      $gossipService: $gossipService
    })
    $scope.note.modal.save = _("Detach")
    # initial volume list.
    serverUrl = $window.$CROSS.settings.serverURL
    $http.get "#{serverUrl}/servers/#{$stateParams.instId}"
      .success (server) ->
        volIds = JSON.parse server['os-extended-volumes:volumes_attached']
        $scope.server = server
        ids = []
        for id in volIds
          ids.push id.id
        params =
          params:
            ids: JSON.stringify ids
            fields: '["display_name", "bootable"]'
        $http.get "#{serverUrl}/volumes/query", params
          .success (volumes) ->
            # initial server
            vols = []
            for vol of volumes
              if volumes[vol]['bootable'] != "true"
                item =
                  text: volumes[vol]['display_name'] || vol
                  value: vol
                vols.push item
            if not vols.length
              vols.push {text: _("No available"), value: -1}
            $scope.modal.fields[0].default = vols
            $scope.form['volume'] = vols[0].value
      .finally ->
        $detachModal.clearLoading()

  .controller 'project.instance.AttachVolumeCtrl', ($scope, $http,
  $window, $q, $stateParams, $state, $gossipService) ->
    $attachModal = new AttachVolumeModal()
    $attachModal.initial($scope, {
      $state: $state
      $http: $http
      instanceId: $stateParams.instId
      $window: $window
      $gossipService: $gossipService
    })
    $scope.note.modal.save = _("Attach")
    # initial volume list.
    serverUrl = $window.$CROSS.settings.serverURL
    volHttp = $http.get "#{serverUrl}/volumes?status=available&bootable=false"
    serHttp = $http.get "#{serverUrl}/servers/#{$stateParams.instId}"
    $q.all([volHttp, serHttp])
      .then (res) ->
        volumes = res[0].data
        $scope.server = res[1].data
        # initial server
        vols = []
        for vol in volumes.data
          item =
            text: vol['display_name'] || vol['id']
            value: vol['id']
          vols.push item
        if not vols.length
          vols.push {text: _("No available"), value: -1}
        $scope.modal.fields[0].default = vols
        $scope.form['volume'] = vols[0].value
      .finally ->
        $attachModal.clearLoading()

  .controller 'project.instance.UnbindIpCtrl', ($scope, $http,
  $window, $q, $stateParams, $state, $gossipService, $instanceSetUp, $interval, $running, floatingIPRefresh) ->
    $unbindModal = new UnbindIpModal()
    $scope.labileInstanceQueue = {}
    $scope.labileStatus = []
    $instanceSetUp $scope, $interval, $running
    $unbindModal.initial($scope, {
      $state: $state
      $http: $http
      instanceId: $stateParams.instId
      $window: $window
      $gossipService: $gossipService
      $floatingIPRefresh: floatingIPRefresh
    })
    $scope.note.modal.save = _("Unbind")
    # initial floating ip list.
    serverUrl = $window.$CROSS.settings.serverURL
    $http.get "#{serverUrl}/servers/#{$stateParams.instId}"
      .success (server) ->
        $scope.server = server
        # initial server
        fIps = []
        addrs = JSON.parse server.addresses
        for pool of addrs
          for add in addrs[pool]
            if add['OS-EXT-IPS:type'] == 'floating'
              item =
                text: add['addr']
                value: add['addr']
              fIps.push item
        if not fIps.length
          fIps.push {text: _("No available"), value: -1}
        $scope.modal.fields[0].default = fIps
        $scope.form['floating_ip'] = fIps[0].value
        $scope.floatingIps = fIps
      .finally ->
        $unbindModal.clearLoading()

  .controller 'project.instance.BindIpCtrl', ($scope, $http,
  $window, $q, $stateParams, $state, $gossipService, $instanceSetUp, $interval, $running, floatingIPRefresh) ->
    $bindModal = new BindIpModal()
    $scope.labileFloatingIPQueue = []
    $scope.labileInstanceQueue = {}
    $scope.labileStatus = []
    $scope.instances = []
    $instanceSetUp $scope, $interval, $running

    $bindModal.initial($scope, {
      $state: $state
      $http: $http
      instanceId: $stateParams.instId
      $window: $window
      $gossipService: $gossipService
      $interval: $interval
      $floatingIPRefresh: floatingIPRefresh
    })
    # initial floating ip list.
    $scope.note.modal.save = _("Bind")
    serverUrl = $window.$CROSS.settings.serverURL
    projectId = $CROSS.person.project.id
    floatingIpHttp = $http.get "#{serverUrl}/os-floating-ips"
    serverHttp = $http.get "#{serverUrl}/servers/#{$stateParams.instId}"
    requestList = [floatingIpHttp, serverHttp]
    if $CROSS.settings.use_neutron == true
      neutronfloatingIpHttp = $http.get "#{serverUrl}/floatingips"
      requestList.push neutronfloatingIpHttp
    $q.all requestList
      .then (rs) ->
        ips = rs[0].data
        server = rs[1].data
        neutronIps = rs[2].data if rs[2]
        $scope.server = server
        fIps = []
        portIgnore = []
        for item of neutronIps
          portIgnore.push neutronIps[item]['fixed_ip_address']
        # initial floating ip
        used = []
        for ip in ips
          if not ip.instance_id
            item =
              text: ip.ip
              value: "#{ip.ip}&#{ip.id}"
            fIps.push item
          else
            used.push ip.fixed_ip
        if not fIps.length
          fIps.push {text: _("No available"), value: -1}
        $scope.modal.fields[0].default = fIps
        $scope.form['floating_ip'] = fIps[0].value
        # initial server
        fixedIps = []
        floatingIps = []
        addrs = JSON.parse server.addresses
        index = 0
        for pool of addrs
          for add in addrs[pool]
            if add['OS-EXT-IPS:type'] == 'floating'
              floatingIps.push add['addr']
            if add['OS-EXT-IPS:type'] == 'fixed'\
            and add['addr'] not in portIgnore
              item =
                text: "#{_('Nic')}vnet#{index}(#{add['addr']})"
                value: add['addr']
              fixedIps.push item
            index += 1
        if not fixedIps.length
          fixedIps.push {text: _("No available"), value: -1}
        $scope.modal.fields[1].default = fixedIps
        $scope.form['fixed_ip'] = fixedIps[0].value
        $scope.floatingIps = floatingIps
        if fixedIps.length == 1
          $scope.modal.fields[1].type = 'hidden'
      .finally ->
        $bindModal.clearLoading()

  .controller 'project.instance.SnapshotCreatCtrl', ($scope, $http,
  $window, $q, $stateParams, $state, $gossipService, getCinderQuota, randomName, getAttachVolFromServer) ->
    _parseBacObject = (snapshotObject) ->
      volSize = 0
      volNum = 0
      for item of snapshotObject
        volSize += JSON.parse snapshotObject[item].size
        volNum++
      return [volNum, volSize]

    $snapshotModal = (new SnapshotCreateModal()).initial($scope, {
      $state: $state
      $http: $http
      instanceId: $stateParams.instId
      $window: $window
      $gossipService: $gossipService
      $randomName: randomName
      $parseBacObject: _parseBacObject
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
    # initial cron backup
    $scope.form['cron_backup'] = false
    $scope.modal.fields[3].type = 'hidden'
    $scope.modal.fields[4].type = 'hidden'
    $scope.modal.fields[5].type = 'hidden'
    # maintenance service must be available
    # if we create server backup cron task
    if 'maintenance' not in $CROSS.permissions
      $scope.modal.fields[2].type = 'hidden'
    $scope.form['rotation'] = 10
    $scope.form['timeout'] = 60

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

  .controller 'project.instance.ResizeCtrl', ($scope, $http,
  $window, $q, $stateParams, $state, $gossipService) ->
    serverUrl = $window.$CROSS.settings.serverURL
    $scope.note =
      desc:
        vcpu: _("CPU(Core)")
        ram: _("Ram(GB)")
        disk: _("Disk(GB)")
        oldFlavor: _("Old flavor")
        newFlavor: _("New flavor")
        compare: _("Compre with old")
        usage: _("Quota usage")
      diskDefault: _("Default")
      selfDefine: _("Custom root disk")
    $scope.modal =
      isDiskDefault: true

    ###
    # Use default or custom root disk.
    ###
    $scope.diskChange = ->
      if $scope.modal.isDiskDefault
        $scope.modal.isDiskDefault = false
        $scope.note.selfDefine = _("Use default")
      else
        $scope.modal.isDiskDefault = true
        $scope.note.selfDefine = _("Custom root disk")

    $resizeModal = new ResizeModal()
    $resizeModal.initial($scope, {
      $state: $state,
      $http: $http,
      instanceId: $stateParams.instId,
      $window: $window
      $gossipService: $gossipService
    })
    $scope.note.modal.save = _("Update")
    serverHttp = $http.get "#{serverUrl}/servers/#{$stateParams.instId}"
    userHttp = $http.get "#{serverUrl}/auth"
    $q.all [serverHttp, userHttp]
      .then (res) ->
        server = res[0].data
        userData = res[1].data
        $scope.server = server
        flavor = JSON.parse server.flavor
        projectId = userData.project.id
        flavorHttp = $http.get "#{serverUrl}/os-flavors/#{flavor.id}"
        quotaHttp = $http.get "#{serverUrl}/nova/os-quota-sets/#{projectId}?usage=true"
        $q.all [quotaHttp, flavorHttp]
          .then (rs) ->
            quota = rs[0].data
            flavor = rs[1].data
            $scope.serverFlavor =
              ram: Number(flavor.ram) / 1024
              disk: Number(flavor.disk)
              vcpus: Number(flavor.vcpus)
            cores =
              used: quota.cores.in_use
              total: quota.cores.limit
              usage: 0
            if cores.total != -1 and cores.total
              cores.usage = cores.used * 100 / cores.total
              cores.usage = parseInt cores.usage
            else if cores.total == -1
              cores.total = _("Unlimited")
            ram =
              used: quota.ram.in_use
              total: quota.ram.limit
              usage: 0
            if ram.total != -1 and ram.total
              ram.usage = ram.used * 100 / ram.total
              ram.usage = parseInt ram.usage
              ram.total = parseInt ram.total / 1024
            else if ram.total == -1
              ram.total = _("Unlimited")
            ram.used = parseInt ram.used / 1024
            $scope.quota =
              cores: cores
              ram: ram
            $scope.form['vcpus'] = $scope.serverFlavor.vcpus
            $scope.form['ram'] = $scope.serverFlavor.ram
            $scope.form['disk'] = $scope.serverFlavor.disk
            for item in $scope.modal.fields[0].default
              if item.value == $scope.form['vcpus']
                item.isActive = 'active'
              if item.value > (cores.total - cores.used)
                item.isDisable = 'disable'
            for item in $scope.modal.fields[1].default
              if item.value == $scope.form['ram']
                item.isActive = 'active'
              if item.value > (ram.total - ram.used)
                item.isDisable = 'disable'
            for item in $scope.modal.fields[2].default
              if item.value == $scope.form['disk']
                item.isActive = 'active'
      .finally ->
        $resizeModal.clearLoading()

    $scope.vcpuClick = (item) ->
      if item.isDisable
        return
      val = item.value
      for item in $scope.modal.fields[0].default
        if val == item.value
          item.isActive = 'active'
        else
          item.isActive = ''
      cores = $scope.quota.cores
      cores.used += val - $scope.form['vcpus']
      if angular.isNumber(cores.total)
        cores.usage = cores.used * 100 / cores.total
        cores.usage = parseInt cores.usage
      $scope.quota.cores = cores
      $scope.form['vcpus'] = val

    $scope.ramClick = (item) ->
      if item.isDisable
        return
      val = item.value
      for item in $scope.modal.fields[1].default
        if val == item.value
          item.isActive = 'active'
        else
          item.isActive = ''
      ram = $scope.quota.ram
      ram.used += val - $scope.form['ram']
      if angular.isNumber(ram.total)
        ram.usage = ram.used * 100 / ram.total
        ram.usage = parseInt ram.usage
      $scope.quota.ram = ram
      $scope.form['ram'] = val

    $scope.diskClick = (item) ->
      val = item.value
      for item in $scope.modal.fields[2].default
        if val == item.value
          item.isActive = 'active'
        else
          item.isActive = ''
      $scope.form['disk'] = val

class DetachVolumeModal extends $cross.Modal
  title: "Detach Volume"
  slug: "detach_volume"
  modalLoading: true

  fields: ->
    [{
      slug: "volume"
      label: _ "Volumes"
      tag: "select"
      default: []
    }]

  handle: ($scope, options) ->
    $http = options.$http
    serverUrl = $CROSS.settings.serverURL
    form = $scope.form
    if form['volume'] == -1
      $scope.tips['volume'] = _("No available volumes")
    serverId = options.instanceId
    message =
      object: "instance-#{serverId}"
      priority: 'info'
      loading: 'true'
      content: _(["Instance %s is %s ...", $scope.server.name, _("detaching")])
    options.$gossipService.receiveMessage message
    $http.delete "#{serverUrl}/servers/#{serverId}/os-volume_attachments/#{form['volume']}"
      .success ->
        options.callback true
      .error (error) ->
        #console.log "Failed to detach volume:", error
        #toastr.error _("Failed to detach volume")
        options.callback false

class AttachVolumeModal extends $cross.Modal
  title: "Attach Volume"
  slug: "attach_volume"
  modalLoading: true

  fields: ->
    [{
      slug: "volume"
      label: _ "Volumes"
      tag: "select"
      default: []
    }]

  handle: ($scope, options) ->
    $http = options.$http
    serverUrl = $CROSS.settings.serverURL
    form = $scope.form
    if form['volume'] == -1
      $scope.tips['volume'] = _("No available volumes")
    data =
      server: form['volume']
    if form['montpoint']
      data['device'] = form['montpoint']
    serverId = options.instanceId
    message =
      object: "instance-#{serverId}"
      priority: 'info'
      loading: 'true'
      content: _(["Instance %s is %s ...", $scope.server.name, _("attaching")])
    options.$gossipService.receiveMessage message
    $http.post "#{serverUrl}/servers/#{serverId}/os-volume_attachments", data
      .success ->
        options.callback true
      .error (error) ->
        #console.log "Failed to attach volume:", error
        #toastr.error _("Failed to attach volume")
        options.callback false

class UnbindIpModal extends $cross.Modal
  title: "Unbind Ip"
  slug: "unbind_ip"
  modalLoading: true

  fields: ->
    [{
      slug: "floating_ip"
      label: _ "Floating Ip"
      tag: "select"
      default: []
    }]

  handle: ($scope, options) ->
    form = $scope.form
    if form['floating_ip'] == -1
      $scope.tips['floating_ip'] = _("No available floating ip")
    params = {
      address: $scope.form['floating_ip']
    }
    params.instanceId = options.instanceId
    message =
      object: "instance-#{params.instanceId}"
      priority: 'info'
      loading: 'true'
      content: _(["Instance %s is %s ...", $scope.server.name, _("removing floating ip")])
    # Dynamic loading floating IP unbind
    if $CROSS.settings.use_neutron == true
      floatingIp = $scope.form['floating_ip']
      floatingIpMeta =
        floatingIpAddr: floatingIp
        floatingIpNum: $scope.floatingIps.length
      options.$floatingIPRefresh floatingIpMeta, false, options.instanceId
    else
      options.$gossipService.receiveMessage message
    $cross.instanceAction 'removeFloatingIp', options.$http, options.$window, params, (status) ->
      if status == 200
        options.callback true
        return
      message =
        object: "instance-#{params.instanceId}"
        priority: 'error'
        content: _(["Failed to remove floating ip from %s", $scope.server.name])
      options.$gossipService.receiveMessage message
      options.callback false

class BindIpModal extends $cross.Modal
  title: "Bind Ip"
  slug: "bind_ip"
  modalLoading: true

  fields: ->
    [{
      slug: "floating_ip"
      label: _ "Floating Ip"
      tag: "select"
      default: []
    }, {
      slug: "fixed_ip"
      label: _ "Nic"
      tag: "select"
      default: []
    }]

  handle: ($scope, options) ->
    form = $scope.form
    serverUrl = $CROSS.settings.serverURL
    if form['floating_ip'] == -1
      $scope.tips['floating_ip'] = _("No available floating ip")
    else if form['fixed_ip'] == -1
      $scope.tips['floating_ip'] = _("No available fixed ip")
    params = {
      address: /(.*)&/g.exec($scope.form['floating_ip'])[1]
      fixed_ip: $scope.form['fixed_ip']
    }
    params.instanceId = options.instanceId
    message =
      object: "instance-#{params.instanceId}"
      priority: 'info'
      loading: 'true'
      content: _(["Instance %s is %s ...", $scope.server.name, _("binding floating ip")])
    # Dynamic loading floating IP bind.
    if $CROSS.settings.use_neutron == true
      netId = /.*&(.*)/g.exec($scope.form['floating_ip'])[1]
      floatingIpMeta =
        floatingIpId: netId
        floatingIpNum: $scope.floatingIps.length
      options.$floatingIPRefresh floatingIpMeta, true, null
    else
      options.$gossipService.receiveMessage message
    $cross.instanceAction 'addFloatingIp', options.$http, options.$window, params, (status, data) ->
      if status == 200
        options.callback true
        return
      message = if data then data.message or '' else ''
      check = /Error: External network .* is not reachable from subnet .*/.test(message)
      content = _(["Failed to bind floating ip to %s", $scope.server.name])
      if check
        content = _(["External network is not reachable, please connect external network using router"])
      message =
        object: "instance-#{params.instanceId}"
        priority: 'error'
        content: content
      options.$gossipService.receiveMessage message
      options.callback false

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
    {
      slug: "cron_backup"
      label: _("Cron backup")
      tag: "input"
      type: "checkbox"
    }
    {
      slug: "timeout"
      label: _ "timeout(s)"
      tag: "input"
      restrictions:
        number: true
        len: [1, 7]
    }
    {
      slug: "cron_table"
      label: _ "Backup at"
      tag: "input"
    }
    {
      slug: 'rotation'
      label: _ "Rotation"
      tag: 'input'
      restrictions:
        len: [1, 3]
        number: true
    }]

  validator: ($scope, options) ->
    quota = $scope.cinderQuota
    $parseBacObject = options.$parseBacObject $scope.form['snapshot_object']
    rs = super($scope, options)
    if not rs
      return false
    volInfo = $parseBacObject
    field = options.field
    volNumCreUsed = volInfo[0] + quota.volumes.in_use
    volSizeCreUsed = volInfo[1] + quota.gigabytes.in_use
    # NOTE(liuhaobo): Check the cinder quota whether enough
    if volNumCreUsed > quota.volumes.limit \
    or volSizeCreUsed > quota.gigabytes.limit
      toastr.error _ "Volume quota is not enough!"
      return false
    # NOTE(liuhaobo): Check user has selected at least one volume
    if field == 'snapshot_object'
      if $scope.form['snapshot_object'].length == 0
        rs = _ "Select at least one volume to back up!"
        $scope.tips[field] = rs
        return false
      else
        $scope.tips[field] = ''

    if field != 'cron_backup'
      return rs
    if $scope.form['cron_backup']
      $scope.modal.fields[3].type = 'text'
      $scope.modal.fields[4].type = 'text'
      $scope.modal.fields[5].type = 'text'
    else
      $scope.modal.fields[3].type = 'hidden'
      $scope.modal.fields[4].type = 'hidden'
      $scope.modal.fields[5].type = 'hidden'

  handle: ($scope, options) ->
    form = $scope.form
    $http = options.$http
    $randomName = options.$randomName
    serverUrl = $CROSS.settings.serverURL
    dataVolume = []
    projectId = $CROSS.person.project.id
    userId = $CROSS.person.user.id
    for item of form['snapshot_object']
      if form['snapshot_object'][item].bootable == 'true'
        systemVolume = form['snapshot_object'][item].id
      else
        dataVolume.push form['snapshot_object'][item]

    if not form['cron_backup']
      # NOTE(liuhaobo): Backup the data volumes
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
            msg = "Meet error when backup data volume:"
            console.error msg, err
            options.callback false
      # NOTE(liuhaobo): Backup the system volume
      if $scope.server.image
        # NOTE(liuhaobo): use createImage API to backup system volume
        $scope.params =
          name: form.name
          metadata: {}
        $scope.params.instanceId = options.instanceId
        message =
          object: "instance-#{$scope.server.id}"
          priority: 'info'
          loading: 'true'
          content: _(["Instance %s in %s ...",
                      $scope.server.name,
                      _("creating backup")])
        options.$gossipService.receiveMessage message
        $cross.instanceAction('snapshot', $http, options.$window,
        $scope.params, (status) ->
          if status == 200
            options.callback true
        )
      else
        # NOTE(liuhaobo): use highland API to backup system volume
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
            msg = "Failed to create system volume backup: %s"
            toastr.error _([msg, $scope.form['name']])
            console.error "Meet error: #{err}"
    else
      date = new Date()
      params =
        name: "VM backup_#{form['name']}_#{date.toLocaleString()}"
        timeout: form['timeout']
        parameters: {}
        template:
          type: 'HL:Nova:Backup'
          task_type: 'cron'
          interval: form['cron_table']
          server: options.instanceId
          backup_name: form['name']
          backup_type: 'daily'
          rotation: form['rotation']
      $http.post "#{serverUrl}/rules", params
        .success (rule) ->
          options.callback false
          params =
            reload: true
            inherit: false
          options.$state.go "project.strategy", null, params
        .error (err) ->
          options.callback false
          console.log "Error: ", err
          toastr.error _("Failed to create cron backup task")

  close: ($scope, options) ->
    options.$state.go "project.instance"

class ResizeModal extends $cross.Modal
  title: "Resize"
  slug: "instance_resize"
  modalLoading: true

  fields: ->
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
    return [{
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
    }]

  handle: ($scope, options) ->
    $http = options.$http
    $window = options.$window
    $state = options.$state
    serverId = options.instanceId
    form = $scope.form
    serverFlavor = $scope.serverFlavor
    if form['ram'] == serverFlavor['ram']
      if form['disk'] == serverFlavor['disk']
        if form['vcpus'] == serverFlavor['vcpus']
          toastr.warning _("Flavor never changed!")
          options.callback false
    opts =
      params:
        ram: form['ram'] * 1024
        disk: form['disk']
        vcpus: form['vcpus']
      $http: $http
      $window: $window
    $cross.nova.createFlavor opts, (err, flavor) ->
      if not err
        ops =
          instanceId: serverId
          flavorId: flavor.id
        message =
          object: "instance-#{serverId}"
          priority: 'info'
          loading: 'true'
          content: _(["Instance %s is %s ...", $scope.server.name, _("resizing")])
        $cross.instanceAction 'resize', $http, $window, ops, (status)->
          options.callback false
          if status == 400
            toastr.error _("Error at resize instance.")
          else
            options.$gossipService.receiveMessage message
          $state.go 'project.instance', {}, {reload: true}
