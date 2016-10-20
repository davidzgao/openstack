'use strict'

angular.module('Unicorn.dashboard.routers')
  .controller 'dashboard.routers.RouterCreateCtr', ($scope, $http,
  $window, $state, $q, $stateParams) ->
    serverURL = $window.$UNICORN.settings.serverURL
    createModal = new RouterCreateModal
    createModal.initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state
    })
    $http.get "#{serverURL}/networks?router:external=True"
      .success (data) ->
        if data.length > 0
          $scope.form['gateway'] = data[0].id
        else
          $scope.form['open'] = false
    $scope.form['open'] = true
  .controller 'dashboard.routers.routerActionCtr', ($scope) ->
    return
  .controller 'dashboard.routers.AddGateway', ($scope, $http, $window,
  $state, $q, $stateParams) ->
    serverURL = $window.$UNICORN.settings.serverURL
    gatewayModal = new AddGatewayModal
    gatewayModal.initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state
      $stateParams: $stateParams
    })
    $http.get "#{serverURL}/networks?router:external=True"
      .success (data) ->
        if data.length > 0
          interfaces = []
          for gateway in data
            if gateway.subnets.length == 0
              continue
            gw = {
              text: gateway.name
              value: gateway.id
            }
            interfaces.push gw
          $scope.modal.fields[0].default = interfaces
        else
          tip = {text: _("No available network"), value: null}
          $scope.modal.fields[0].default = [tip]
    $scope.note.modal.save = _("Open")
  .controller 'dashboard.routers.AddPort', ($scope, $http, $window,
  $state, $q, $stateParams) ->
    serverURL = $window.$UNICORN.settings.serverURL
    addPortModal = new AddPortModal
    addPortModal.initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state
      $stateParams: $stateParams
    })
    $scope.note.modal.save = _ "Relative"
    currentId = $stateParams.rId
    tenantId = $UNICORN.person.project.id
    ports = $http.get "#{serverURL}/ports"
    routers = $http.get "#{serverURL}/routers"
    networks = $http.get "#{serverURL}/networks"
    subnets = $http.get "#{serverURL}/subnets"
    $q.all([ports, networks, subnets, routers])
      .then (values) ->
        portList = values[0].data
        networkList = values[1].data
        subnetList = values[2].data
        routerList = values[3].data
        relativedDevice = {}
        relativedSubnet = {}
        for port in portList
          if !relativedDevice[port.device_id]
            relativedDevice[port.device_id] = []
          relativedDevice[port.device_id].push port
        for router in routerList
          if relativedDevice[router.id]
            ports = relativedDevice[router.id]
            for port in ports
              for sub in port.fixed_ips
                relativedSubnet[sub.subnet_id] = router
        networkMap = {}
        for network, index in networkList
          networkMap[network.id] = network
        availableSub = []
        # Filter unavailable network
        for subnet in subnetList
          subnet.network = networkMap[subnet.network_id]
          subnet.network_name = subnet.network.name
          # Remove subnet which has linked
          if relativedSubnet[subnet.id]
            continue
          if subnet.network['router:external']
            continue
          # Remove network that not in current project and not shared
          if subnet.tenant_id != tenantId
            if not subnet.network['shared']
              continue
          item = {
            text: "#{subnet.name}: #{subnet.cidr}(#{subnet.network_name})"
            value: "#{subnet.id}:#{subnet.network.id}"
            cidr: subnet.cidr
          }
          availableSub.push item
        addPortModal.clearLoading()
        if availableSub.length > 0
          $scope.modal.fields[0].default = availableSub
          $scope.form.subnet = availableSub[0].value
        else
          tip = {text: _("No available subnet."), value: null}
          $scope.modal.fields[0].default = [tip]

class RouterCreateModal extends $unicorn.Modal
  title: 'Create Router'
  slug: 'router_create'
  single: true

  fields: ->
    [{
      slug: 'name'
      label: _("Name")
      tag: 'input'
      restrictions:
        required: true
        len: [1, 32]
    }, {
      slug: 'open'
      label: _("Open Gateway")
      tag: 'input'
      type: 'checkbox'
    }, {
      slug: 'gateway'
      label: _ 'Gateway'
      type: 'hidden'
      default: ''
    }]

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    serverURL = $UNICORN.settings.serverURL
    tenantId = $UNICORN.person.project.id
    form = $scope.form
    param = {
      name: form.name
      tenant_id: tenantId
    }
    if form.open
      if form.gateway
        param['external_gateway_info'] = {
          network_id: form.gateway
        }
      else
        nullExternal = true
    $http.post "#{serverURL}/routers", param
      .success (data) ->
        if nullExternal
          toastr.info _("Success to create router, but has not external network in system, can not open external gateway of the router.")
        else
          toastr.success _("Success to create router.")
          $state.go '^', {}, {reload: true}
      .error (err) ->
        toastr.error _("Failed to create router.")
        $state.go '^', {}, {reload: true}

class AddGatewayModal extends $unicorn.Modal
  title: _ 'Add Gateway'
  slug: 'add_gateway'
  single: true

  fields: ->
    [{
      slug: 'gateway'
      label: _ "Gateway"
      type: 'select'
      tag: 'select'
      default: []
    }]

  validator: ($scope, options) ->
    field = options.field
    gateway = $scope.form['gateway']
    if not gateway
      return false
    else
      return true

  close: ($scope, options) ->
    $state = options.$state
    $state.go 'dashboard.routers'

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    $stateParams = options.$stateParams
    serverURL = $UNICORN.settings.serverURL
    form = $scope.form
    param = {
      external_gateway_info:
        network_id: form.gateway
    }
    routerId = $stateParams.rId
    routerURL = "#{serverURL}/routers/#{routerId}"
    $http.put routerURL, param
      .success (data) ->
        toastr.success _("Successfully open external gateway.")
        $state.go 'dashboard.routers', {}, {reload: true}
      .error (err) ->
        toastr.error _("Error at open external network!")
        $state.go 'dashboard.routers'
    return true

class AddPortModal extends $unicorn.Modal
  title: _ 'Add Port'
  slug: 'add_port'
  single: true
  modalLoading: true

  fields: ->
    [{
      slug: 'subnet'
      label: _ "Subnet"
      type: 'select'
      tag: 'select'
      default: []
      restrictions:
        required: true
    }, {
      slug: 'ip'
      label: _ "IP Address"
      tag: 'ipinput'
      default: []
      type: 'hidden'
    }]

  close: ($scope, options) ->
    $state = options.$state
    $state.go 'dashboard.routers'

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    $stateParams = options.$stateParams
    serverURL = $UNICORN.settings.serverURL
    tenantId = $UNICORN.person.project.id
    form = $scope.form
    routerId = $stateParams.rId
    addInterfaceURL = "#{serverURL}/routers/#{routerId}/add_router_interface"
    netInfo = form.subnet.split(':')
    if form.ip
      # Create Port then add interface to router
      networkId = netInfo[1]
      subNetId = netInfo[0]
      portParam = {
        network_id: networkId
        tenant_id: tenantId
        fixed_ips: [{
          subnet_id: subNetId
          ip_address: form.ip
        }]
      }
      portURL = "#{serverURL}/ports"
      $http.post portURL, portParam
        .success (data) ->
          param = {
            port_id: data.id
          }
          $http.put addInterfaceURL, param
            .success (data) ->
              toastr.success _("Success add interface.")
            .error (error) ->
              toastr.error _("Failed to add interface.")
        .error (error) ->
          toastr.error _("Failed to add interface.")
    else
      param = {
        subnet_id: netInfo[0]
      }
      $http.put addInterfaceURL, param
        .success (data) ->
          toastr.success _("Success add interface.")
        .error (error) ->
          toastr.error _("Failed to add interface.")

    $state.go 'dashboard.routers', {}, {reload: true}
    return true
