app = angular.module("Cross.modal", [
  "ui.router",
  "ui.bootstrap"
])

app.provider "$modalState", ($stateProvider) ->
    provider = @
    provider.$get = ->
      return provider

    provider.state = (stateName, options) ->
      modalInstance = undefined
      $stateProvider.state stateName, {
        modal: true
        url: options.url
        params: options.params
        substate: options.substate || true
        onEnter: ["$modal", "$state", ($modal, $state) ->
          if options.larger
            options.windowClass = "window-larger"
          # I don't want user to close the modal by pressing on backdrop.
          # A modal can only be closed by pressing close button created.
          options.backdrop = 'static'
          modalInstance = $modal.open(options)
          modalInstance.result.finally ->
            modalInstance = null
            if $state.$current.name == stateName
              $state.go options.successState
        ]
        onExit: ->
          if modalInstance
            modalInstance.close()
      }
    return provider

app.factory '$imageCreate', ['$window', '$http', '$q', '$state',
($window, $http, $q, $state) ->
  class ImageCreateModal extends $cross.Modal
    title: "Create Image"
    slug: "image_create"
    single: false
    parallel: true
    containFile: true
    steps: ['basic', 'others']

    validator: ($scope, options) ->
      rs = super($scope, options)
      if not rs
        return false
      step = options.step
      field = options.field
      if step == 'basic' and field == 'source'
        if $scope.form['basic']['source'] == 'local'
          $scope.modal.steps[0].fields[4].type = 'hidden'
          $scope.modal.steps[0].fields[5].type = 'file'
          $scope.restrictions["#{step}_url"].required = false
        else
          $scope.modal.steps[0].fields[4].type = 'text'
          $scope.modal.steps[0].fields[5].type = 'hidden'
          $scope.restrictions["#{step}_url"].required = true
      if step == 'basic' and field == 'format'
        if $scope.form['basic']['format'] == 'vmdk'
          $scope.modal.steps[0].fields[2].default = [{
            text: _("Windows 8 (64 bit)")
            value: "windows8_64Guest"
          }, {
            text: _("Windows 8 (32 bit)")
            value: "windows8Guest"
          }, {
            text: _("Windows 8 Server (64 bit)")
            value: "windows8Server64Guest"
          }, {
            text: _("Windows Server 2008 R2 (64 bit)")
            value: "windows7Server64Guest"
          }, {
            text: _("Windows 7 (64 bit)")
            value: "windows7_64Guest"
          }, {
            text: _("Windows 7 (32 bit)")
            value: "windows7Guest"
          }, {
            text: _("Windows Server 2003, Enterprise Edition (64 bit)")
            value: "winNetEnterprise64Guest"
          }, {
            text: _("Windows Server 2003, Enterprise Edition (32 bit)")
            value: "winNetEnterpriseGuest"
          }, {
            text: _("Windows Server 2003, Standard Edition (64 bit)")
            value: "winNetStandard64Guest"
          }, {
            text: _("Windows Server 2003, Standard Edition (32 bit)")
            value: "winNetStandardGuest"
          }, {
            text: _("CentOS 4/5 (64-bit)")
            value: "centos64Guest"
          }, {
            text: _("CentOS 4/5 (32 bit)")
            value: "centosGuest"
          }, {
            text: _("Ubuntu Linux (64 bit)")
            value: "ubuntu64Guest"
          }, {
            text: _("Ubuntu Linux (32 bit)")
            value: "ubuntuGuest"
          }, {
            text: _("Debian GNU/Linux 6 (64 bit)")
            value: "debian6_64Guest"
          }, {
            text: _("Debian GNU/Linux 6 (32 bit)")
            value: "debian6Guest"
          }, {
            text: _("Debian GNU/Linux 7 (64 bit)")
            value: "debian7_64Guest"
          }, {
            text: _("Debian GNU/Linux 7 (32 bit)")
            value: "debian7Guest"
          }, {
            text: _("Red Hat Enterprise Linux 6 (64 bit)")
            value: "rhel6_64Guest"
          }, {
            text: _("Red Hat Enterprise Linux 6 (32 bit)")
            value: "rhel6Guest"
          }, {
            text: _("Red Hat Enterprise Linux 5 (64 bit)")
            value: "rhel5_64Guest"
          }, {
            text: _("Red Hat Enterprise Linux 5 (32 bit)")
            value: "rhel5Guest"
          }, {
            text: _("Linux (64 bit)")
            value: "otherLinux64Guest"
          }, {
            text: _("Other Operating System (64 bit)")
            value: "otherGuest64"
          }, {
            text: _("Other Operating System (32 bit)")
            value: "otherGuest"
          }]
        else
          $scope.modal.steps[0].fields[2].default = [{
            text: _("windows")
            value: 'windows'
          }, {
            text: _("linux")
            value: 'linux'
          }]
      return rs

    step_basic: ->
      urlReg = ///^(http|https|ftp)\://([a-zA-Z0-9\.\-]+(\:[a-zA-
               Z0-9\.&%\$\-]+)*@)?((25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{
               2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}
               [0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|
               [0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-
               4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])|([a-zA-Z0
               -9\-]+\.)*[a-zA-Z0-9\-]+\.[a-zA-Z]{2,4})(\:[0-9]+)?(/
               [^/][a-zA-Z0-9\.\,\?\'\\/\+&%\$\=~_\-@]*)*$///
      osTypes = [{
        text: _("windows")
        value: 'windows'
      }, {
        text: _("linux")
        value: 'linux'
      }]
      if $CROSS.settings.osTypes
        osTypes = []
        for os in $CROSS.settings.osTypes
          item =
            text: os
            value: os
          osTypes.push item
      name: _("Basic info")
      fields: [{
        slug: 'name'
        label: _("Name")
        tag: 'input'
        restrictions:
          required: true
          len: [1, 32]
      }, {
        slug: 'format'
        label: _("Format")
        tag: 'select'
        default: [{
          value: 'qcow2'
          text: _('QCOW2 - QEMU Emulator')
        }, {
          value: 'iso'
          text: _('ISO - Optical Disk Image')
        }, {
          value: 'raw'
          text: 'Raw'
        }, {
          value: 'vdi'
          text: 'VDI'
        }, {
          value: 'vhd'
          text: 'VHD'
        }, {
          value: 'vmdk'
          text: 'VMDK'
        }]
      }, {
        slug: 'os_type'
        label: _("OS type")
        tag: 'select'
        default: osTypes
      }, {
        slug: 'source'
        label: _("Image source")
        tag: 'select'
        default: [{
          text: _("Web link")
          value: 'web'
        }, {
          text: _("Local")
          value: 'local'
        }]
      }, {
        slug: 'url'
        label: _("Image url")
        tag: 'input'
        restrictions:
          required: true
          regex: [new RegExp(urlReg), _("Must be url")]
      }, {
        slug: 'local'
        label: _("Local")
        tag: 'input'
        type: 'file'
      }, {
        slug: 'is_public'
        label: _("Is public")
        tag: 'input'
        type: 'checkbox'
      }]

    step_others: ->
      name: _("Other info")
      fields: [{
        slug: 'username'
        label: _("Username")
        tag: 'input'
        restrictions:
          len: [1, 32]
      }, {
        slug: 'password'
        label: _("Password")
        tag: 'input'
      }, {
        slug: 'description'
        label: _("Description")
        tag: 'textarea'
      }, {
        slug: 'min_ram'
        label: _("Min ram(GB)")
        tag: 'input'
        restrictions:
          float: true
      }, {
        slug: 'min_disk'
        label: _("Min disk(GB)")
        tag: 'input'
        restrictions:
          number: true
      }, {
        slug: 'self_define'
        tag: 'self-defined'
      }]

    handle: ($scope, options) ->
      $http = options.$http
      $state = options.$state
      serverUrl = $CROSS.settings.serverURL
      form = $scope.form
      containerFormat = 'bare'
      if form['basic']['format'] in ['ami', 'aki', 'ari']
        containerFormat = form['basic']['format']
      data =
        name: escape(form['basic']['name'])
        is_public: form['basic']['is_public']
        disk_format: form['basic']['format']
        container_format: containerFormat
      if form['others']['min_ram']
        data['min_ram'] = Math.ceil(form['others']['min_ram'] * 1024)
      if form['others']['min_disk']
        data['min_disk'] = form['others']['min_disk']
      if form['basic']['source'] == 'web'
        data['copy_from'] = form['basic']['url']
      file = undefined
      if form['basic']['source'] == 'local'
        file = angular.element("input[type='file']")[0].files[0]
      properties = form['others']['self_define'] || {}
      if form['others']['username']
        properties['username'] = escape(form['others']['username'])
      if form['others']['password']
        properties['password'] = form['others']['password']
      if form['others']['description']
        properties['description'] = escape(form['others']['description'])
      if form['basic']['os_type']
        if form['basic']['format'] == 'vmdk'
          properties['vmware_ostype'] = form['basic']['os_type']
          if form['basic']['os_type'].indexOf('win') == 0
            properties['os_type'] = 'windows'
          else
            properties['os_type'] = 'linux'
        else
          properties['os_type'] = form['basic']['os_type']
      hypervisor_type = $CROSS.settings.hypervisor_type
      if hypervisor_type and hypervisor_type.toLocaleLowerCase() == 'vmware'
        properties['vmware_disktype'] = $CROSS.settings.vmwareDisktype.toLocaleLowerCase()
        properties['vmware_adaptertype'] = $CROSS.settings.vmwareAdaptertype.toLocaleLowerCase()
      pro_new = {}
      for k of properties
        val = properties[k]
        k = escape(k)
        pro_new[k] = escape(val)
      data['properties'] = pro_new
      headers =
        'Content-Type': undefined
        'X-Image-Meta': JSON.stringify data
      is_admin = options.is_admin
      dash = if is_admin then "admin" else "project"
      $http.post("#{serverUrl}/images", file, {
        transformRequest: angular.identity
        headers: headers
      }).success (image) ->
          options.callback false
          $state.go "#{dash}.image", {}, {reload: true}
        .error (err) ->
          toastr.error _("Failed to create image.")
          options.callback false

  return ($scope, is_public) ->
    (new ImageCreateModal()).initial($scope, {
      $window: $window
      $q: $q
      is_admin: is_public
      $http: $http
      $state: $state})
    steps0 = $scope.modal.steps[0].fields
    $scope.form['basic']['os_type'] = steps0[1].default[0].value
    $scope.form['basic']['format'] = steps0[2].default[0].value
    $scope.form['basic']['source'] = steps0[3].default[0].value
    $scope.modal.steps[0].fields[5].type = 'hidden'
    $scope.form['basic']['is_public'] = false
    if not is_public
      $scope.modal.steps[0].fields[6].type = 'hidden'
    $scope.form['others']['self_define'] = {}

    # initial self define.
    $scope.note.custom = _("Custom attributes")
    $scope.modal.selfDefine = false

    $scope.showOrHide = ->
      if $scope.modal.selfDefine
        $scope.modal.selfDefine = false
      else
        $scope.modal.selfDefine = true

    validKeyOrValue = (val, isKey) ->
      if val == undefined or val == ""
        if isKey
          $scope.tips['others']['self_define'] = _("Key could not be empty")
          return false
        return true
      if isKey
        if $scope.form['others']['self_define'][val] != undefined
          $scope.tips['others']['self_define'] = _("Key is already exist")
          return
      if val.length > 32
        $scope.tips["others"]['self_define'] = _("Length must be shorter than 33")
        return
      $scope.tips["others"]['self_define'] = ""
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
      $scope.form['others']['self_define'][key] = value
      $scope.modal.defineKey = ""
      $scope.modal.defineValue = ""

    $scope.defineMinues = (key) ->
      delete $scope.form['others']['self_define'][key]
  ]
