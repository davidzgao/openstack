'use strict'

angular.module('Cross.project.networks')
  .controller 'project.networks.NetworkCreateCtr', ($scope, $http,
  $window, $state, $q, $stateParams) ->
    ipsets = [
      {
        passages: [
          {
            default: 192
            disable: true
          }, {
            default: 168
            disable: true
          }, {
            range: {
              min: 0
              max: 255
            }
            default: 0
            disable: false
            tip: "0~255"
          }, {
            default: 0
            disable: true
            tip: ""
          }
        ]
        showCidr: true
        cidr: {
          disable: true
          default: 24
          tip: "8~30"
        }
      },
      {
        passages: [
          {
            default: 10
            disable: true
          }, {
            range: {
              min: 0
              max: 255
            }
            tip: "0~255"
            default: 0
            disable: false
          }, {
            range: {
              min: 0
              max: 255
            }
            disable: false
            default: 0
            tip: "0~255"
          }, {
            range: {
              min: 0
              max: 255
            }
            default: 0
            disable: false
            tip: "0~255"
          }
        ]
        showCidr: true
        cidr: {
          disable: false
          default: 24
          tip: "8~30"
        }
      },
      {
        passages: [
          {
            default: 172
            disable: true
          }, {
            range: {
              min: 16
              max: 31
            }
            default: 16
            disable: false
            tip: "16~31"
          }, {
            range: {
              min: 0
              max: 255
            }
            default: 0
            disable: false
            tip: "0~255"
          }, {
            default: 0
            disable: false
            tip: ""
          }
        ]
        showCidr: true
        cidr: {
          disable: false
          default: 24
          tip: "8~30"
        }
      }
    ]
    serverURL = $window.$CROSS.settings.serverURL
    tenantId = $CROSS.person.project.id
    createSubnet = () ->
      $scope.subnetsName = []
      subnets = $http.get "#{serverURL}/subnets"
      $q.all([subnets])
        .then (values) ->
          for subnet in values[0].data
            if subnet.tenant_id == tenantId
              $scope.subnetsName.push subnet.name
      createModal = new SubnetCreateModal
      createModal.initial($scope, {
        $window: $window
        $q: $q
        $http: $http
        $state: $state
      })
      $scope.ipSelected = 0
      $scope.selectChange = (index) ->
        if index != $scope.ipSelected
          $scope.ipSelected = index
      $scope.modal.fields[2].default = ipsets
      tenantId = $CROSS.person.project.id
      $http.get "#{serverURL}/networks?tenant_id=#{tenantId}"
        .success (data) ->
          items = []
          for network in data
            item = {
              text: network.name
              value: network.id
            }
            items.push item
          $scope.modal.fields[1].default = items
          $scope.form['network'] = items[0]
    createNetwork = () ->
      $scope.networksName = []
      $scope.subnetsName = []
      networks = $http.get "#{serverURL}/networks"
      subnets = $http.get "#{serverURL}/subnets"
      $q.all([networks, subnets])
        .then (values) ->
          for network in values[0].data
            if network.tenant_id == tenantId
              $scope.networksName.push network.name
          for subnet in values[1].data
            if subnet.tenant_id == tenantId
              $scope.subnetsName.push subnet.name
      createModal = new NetworkCreateModal
      createModal.initial($scope, {
        $window: $window
        $q: $q
        $http: $http
        $state: $state
      })
      $scope.ipSelected = 0
      $scope.selectChange = (index) ->
        if index != $scope.ipSelected
          $scope.ipSelected = index
      $scope.modal.fields[3].default = ipsets

      $scope.form['create_subnet'] = true
      $scope.$watch 'form', (newVal) ->
        if newVal['create_subnet']
          $scope.modal.fields[2].type = ''
          $scope.modal.fields[3].type = ''
          $scope.modal.fields[4].type = ''
        else
          $scope.modal.fields[2].type = 'hidden'
          $scope.modal.fields[3].type = 'hidden'
          $scope.modal.fields[4].type = 'hidden'
      , true
    if $state.params.tab == 'subnet'
      createSubnet()
    else
      createNetwork()
  .controller 'project.networks.networkActionCtr', ($scope) ->
    return
  .controller 'project.networks.createSubAction', ($scope, $http,
  $window, $state, $q, $stateParams) ->
    serverURL = $window.$CROSS.settings.serverURL
    tenantId = $CROSS.person.project.id
    $scope.subnetsName = []
    subnets = $http.get "#{serverURL}/subnets"
    $q.all([subnets])
      .then (values) ->
        for subnet in values[0].data
          if subnet.tenant_id == tenantId
            $scope.subnetsName.push subnet.name
    modal = new NetworkCreateSubModal
    modal.initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state
      $stateParams: $stateParams
    })
    networkId = $stateParams.nId
    $scope.form['network_id'] = networkId
  .controller 'project.networks.attachAction', ($scope, $http,
  $window, $state, $q, $stateParams) ->
    serverURL = $window.$CROSS.settings.serverURL
    subnetId = $stateParams.nId
    tenantId = $CROSS.person.project.id
    modal = new RelRouterModal
    modal.initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state
      $stateParams: $stateParams
    })
    $scope.form['subnet'] = subnetId
    $http.get "#{serverURL}/routers?tenant_id=#{tenantId}"
      .success (data) ->
        items = []
        for router in data
          item = {
            text: router.name
            value: router.id
          }
          items.push item
        $scope.modal.fields[0].default = items
        $scope.form['router'] = items[0]

class NetworkCreateSubModal extends $cross.Modal
  title: 'Create Subnet'
  slug: 'network_create'
  single: true

  fields: ->
    [{
      slug: 'subnet_name'
      label: _("Subnet Name")
      tag: 'input'
      restrictions:
        func: ($scope, val) ->
          if val in $scope.subnetsName
            return _ "This value has been took up."
        len: [1, 32]
    }, {
      slug: 'ip_address'
      label: _("CIDR")
      tag: 'input'
      restrictions:
        required: true
        cidr: true
    }, {
      slug: 'network_id'
      label: _("Network")
      tag: 'input'
      type: 'hidden'
    }, {
      slug: 'dns_nameservers'
      label: _("DNS name servers")
      tag: 'textarea'
    }]

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    serverURL = $CROSS.settings.serverURL
    subnetURL = "#{serverURL}/subnets"
    form = $scope.form
    if form.dns_nameservers
      nameservers = form.dns_nameservers.split(' ')
    else
      nameservers = $CROSS.settings.defaut_nameservers ||\
      ['8.8.8.8']
    subnetParam = {
      name: form.subnet_name
      ip_version: 4,
      cidr: form.ip_address
      network_id: form.network_id
      dns_nameservers: nameservers
    }
    $http.post subnetURL, subnetParam
      .success (subnet) ->
        $state.go "project.networks", {}, {reload: true}
        toastr.success _("Success to create subnet.")
        return true
      .error (err) ->
        $state.go "project.networks", {}, {reload: true}
        toastr.error _("Failed to create subnet.")
        return true
    return true

class NetworkCreateModal extends $cross.Modal
  title: 'Create Network'
  slug: 'network_create'
  single: true

  fields: ->
    [{
      slug: 'name'
      label: _('Name')
      tag: 'input'
      restrictions:
        func: ($scope, val) ->
          if val in $scope.networksName
            return _ "This value has been took up."
        required: true
        len: [1, 32]
    }, {
      slug: 'create_subnet'
      label: _("Create Subnet")
      tag: 'input'
      type: 'checkbox'
    }, {
      slug: 'subnet_name'
      label: _("Subnet Name")
      tag: 'input'
      restrictions:
        func: ($scope, val) ->
          if val in $scope.subnetsName
            return _ "This value has been took up."
        len: [1, 32]
    }, {
      slug: 'cidr'
      label: _("CIDR")
      tag: 'ipinput'
      ipSelect: true
      default: []
    }, {
      slug: 'dns_nameservers'
      label: _("DNS name servers")
      tag: 'textarea'
    }]

  validator: ($scope, options) ->
    res = super($scope, options)
    if $scope.form.create_subnet
      field = options.field
      ip = $scope.modal.fields[3].default[$scope.ipSelected]
      $scope.form['ip_address'] = ip.value
      ipTest = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$/
      if !ipTest.test(ip.value)
        ip.invalid = 'invalid'
        return false
      else
        ip.invalid = 'valid'
      return res
    else
      return res

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    serverURL = $CROSS.settings.serverURL
    tenantId = $CROSS.person.project.id
    form = $scope.form
    networkParam = {
      name: form.name
      admin_state_up: true
      tenant_id: tenantId
    }
    networkURL = "#{serverURL}/networks"
    subnetURL = "#{serverURL}/subnets"
    $http.post networkURL, networkParam
      .success (data) ->
        if form.create_subnet
          if form.dns_nameservers
            nameservers = form.dns_nameservers.split(' ')
          else
            nameservers = $CROSS.settings.defaut_nameservers ||\
            ['8.8.8.8']
          subnetParam = {
            name: form.subnet_name
            ip_version: 4,
            cidr: form.ip_address
            network_id: data.id
            tenant_id: tenantId
            dns_nameservers: nameservers
          }
          $http.post subnetURL, subnetParam
            .success (subnet) ->
              toastr.success _("Success to create network and subnet.")
              $state.go "project.networks", {}, {reload: true}
              return true
        else
          toastr.success _("Success to create network.")
          $state.go "project.networks", {}, {reload: true}
      .error (err) ->
        toastr.error _ "Error at create network."
        $state.go "project.networks", {}, {reload: true}

class SubnetCreateModal extends $cross.Modal
  title: 'Create Subnet'
  slug: 'subnet_create'
  single: true

  fields: ->
    [{
      slug: 'name'
      label: _('Name')
      tag: 'input'
      restrictions:
        func: ($scope, val) ->
          if val in $scope.subnetsName
            return _ "This value has been took up."
        required: true
        len: [1, 32]
    }, {
      slug: 'network'
      label: _("Select Network")
      tag: 'select'
      default: []
    }, {
      slug: 'cidr'
      label: _("CIDR")
      tag: 'ipinput'
      default: []
    }, {
      slug: 'dns_nameservers'
      label: _("DNS name servers")
      tag: 'textarea'
    }]

  validator: ($scope, options) ->
    res = super($scope, options)
    field = options.field
    ip = $scope.modal.fields[2].default[$scope.ipSelected]
    $scope.form['cidr'] = ip.value
    ipTest = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$/
    if !ipTest.test(ip.value)
      ip.invalid = 'invalid'
      return false
    else
      ip.invalid = 'valid'
    return res

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    serverURL = $CROSS.settings.serverURL
    tenantId = $CROSS.person.project.id
    form = $scope.form
    if form.dns_nameservers
      nameservers = form.dns_nameservers.split(' ')
    else
      nameservers = $CROSS.settings.defaut_nameservers ||\
      ['8.8.8.8']
    subnetParam = {
      name: form.name
      ip_version: 4,
      cidr: form.cidr
      network_id: form.network
      tenant_id: tenantId
      dns_nameservers: nameservers
    }
    subnetURL = "#{serverURL}/subnets"
    $http.post subnetURL, subnetParam
      .success (data) ->
        toastr.success _("Success to create subnet.")
        $state.go "project.networks", {tab: 'subnet'}, {reload: true}
      .error (err) ->
        toastr.error _ "Error at create network."
        $state.go "project.networks", {tab: 'subnet'}, {reload: true}

class RelRouterModal extends $cross.Modal
  title: _ "Relative Router"
  slug: 'rel_router'
  single: true

  fields: ->
    [{
      slug: 'router'
      label: _ "Router"
      type: 'select'
      tag: 'select'
      default: []
      restrictions:
        required: true
    }, {
      slug: 'subnet'
      label: _ "Subnet"
      tag: 'input'
      type: 'hidden'
    }]

  close: ($scope, options) ->
    $state = options.$state
    $state.go 'project.networks'

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    $stateParams = options.$stateParams
    serverURL = $CROSS.settings.serverURL
    form = $scope.form
    routerId = form.router
    subnetId = form.subnet
    actionURL = "#{serverURL}/routers/#{routerId}/add_router_interface"
    param = {
      subnet_id: subnetId
    }
    $http.put actionURL, param
      .success (data) ->
        toastr.success _("Success to bind router!")
      .error (error) ->
        toastr.error _("Failed to bind router!")

    $state.go 'project.networks', {tab: 'subnet'}, {reload: true}
    return true
