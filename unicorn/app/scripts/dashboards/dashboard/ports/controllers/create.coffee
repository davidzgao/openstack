'use strict'

angular.module('Unicorn.dashboard.ports')
  .controller 'dashboard.ports.PortCreateCtr', ($scope, $http,
  $window, $state, $q, $stateParams) ->
    serverURL = $window.$UNICORN.settings.serverURL
    createModal = new PortCreateModal
    createModal.initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state
    })
    tenantId = $UNICORN.person.project.id
    networks = $http.get "#{serverURL}/networks?tenant_id=#{tenantId}"
    subnets = $http.get "#{serverURL}/subnets?tenant_id=#{tenantId}"
    $q.all([networks, subnets])
      .then (values) ->
        networkList = values[0].data
        subnetList = values[1].data
        networkMap = {}
        sub_nets = []
        for network in networkList
          networkMap[network.id] = network
        for subnet in subnetList
          if networkMap[subnet.network_id]
            subnet.network_name = networkMap[subnet.network_id].name
          item = {
            value: "#{subnet.network_id}:#{subnet.id}"
            text: "#{subnet.name} - #{subnet.cidr}"
            group: subnet.network_name
          }
          sub_nets.push item
        $scope.modal.fields[0].default = sub_nets

    $http.get "#{serverURL}/os-security-groups"
      .success (data) ->
        secs = []
        for sec in data
          item = {
            value: sec.id
            text: sec.name
          }
          secs.push item
        $scope.modal.fields[2].default = secs
        $scope.form['security'] = sec[0]

  .controller 'dashboard.ports.portActionCtr', ($scope) ->
    return
  .controller 'dashboard.ports.attachAction', ($scope, $http,
  $window, $state, $q, $stateParams) ->
    serverURL = $window.$UNICORN.settings.serverURL
    modal = new PortAttachModal
    modal.initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state
    })
    $scope.portId = $stateParams.pId
    $scope.form['port_id'] = $scope.portId
    tenantId = $UNICORN.person.project.id
    $http.get "#{serverURL}/servers?tenant_id=#{tenantId}"
      .success (data) ->
        instances = data.data
        items = []
        for instance in instances
          item = {
            text: instance.name
            value: instance.id
            status: instance["OS-EXT-STS:vm_state"]
          }
          if item.status == "active"
            items.push item

        $scope.modal.fields[0].default = items
        $scope.form['instance'] = items[0]

class PortCreateModal extends $unicorn.Modal
  title: 'Create Port'
  slug: 'port_create'
  single: true

  fields: ->
    [{
      slug: 'network_id'
      label: _("Choice Subnet")
      tag: 'select'
      type: 'select'
      default: []
      restrictions:
        required: true
    }, {
      slug: 'ip_address'
      label: _("IP Address")
      tag: 'input'
    }, {
      slug: 'security'
      label: _("Security Group")
      tag: 'select'
      type: 'select'
      default: []
      restrictions:
        required: true
    }]

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    serverURL = $UNICORN.settings.serverURL
    tenantId = $UNICORN.person.project.id
    form = $scope.form
    netInfo = form.network_id.split(':')
    portParam = {
      network_id: netInfo[0]
      fixed_ips: [{
        subnet_id: netInfo[1]
      }]
      admin_state_up: true
      tenant_id: tenantId
    }
    if form.ip_address
      portParam['fixed_ips'] = [{
        subnet_id: netInfo[1]
        ip_address: form.ip_address
      }]
    $http.post "#{serverURL}/ports", portParam
      .success (data) ->
        toastr.success _("Success to create port.")
        $state.go "dashboard.ports", {}, {reload: true}
      .error (err) ->
        if err.type == "IpAddressInUse"
          toastr.error _(["The IP address %s is in use.", portParam.fixed_ips[0].ip_address])
        else
          toastr.error _("Failed to create port.")
        $state.go "dashboard.ports", {}


class PortAttachModal extends $unicorn.Modal
  title: 'Attach Instance'
  slug: 'port_attach'
  single: true

  fields: ->
    [{
      slug: 'instance'
      label: _('Instance')
      tag: 'select'
      default: []
      restrictions:
        required: true
    }, {
      slug: 'port_id'
      label: 'port'
      tag: 'input'
      type: 'hidden'
    }]

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    serverURL = $UNICORN.settings.serverURL
    form = $scope.form

    attachURL = "#{serverURL}/servers/#{form.instance}/os-interface"
    param = {
      interfaceAttachment: {
        port_id: form.port_id
      }
    }
    $http.post attachURL, param
      .success (data) ->
        toastr.success _("Success attach to instance!")
        $state.go 'dashboard.ports', {}, {reload: true}
      .error (err) ->
        toastr.error _("Failed attach to instance!")
        $state.go 'dashboard.ports', {}, {reload: true}

    return
