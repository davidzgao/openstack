'use strict'

angular.module('Cross.project.ports')
  .controller 'project.ports.PortCreateCtr', ($scope, $http,
  $window, $state, $q, $stateParams) ->
    serverURL = $window.$CROSS.settings.serverURL
    createModal = new PortCreateModal
    createModal.initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state
    })
    tenantId = $CROSS.person.project.id
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

  .controller 'project.ports.portActionCtr', ($scope) ->
    return
  .controller 'project.ports.attachAction', ($scope, $http,
  $window, $state, $q, $stateParams, $interval) ->
    serverURL = $window.$CROSS.settings.serverURL
    modal = new PortAttachModal
    modal.initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state
      $interval: $interval
      $stateParams: $stateParams
    })
    $scope.portId = $stateParams.pId
    $scope.form['port_id'] = $scope.portId
    tenantId = $CROSS.person.project.id
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

class PortCreateModal extends $cross.Modal
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
      restrictions:
        ip: true
    }, {
      slug: 'security'
      label: _("Security Group")
      tag: 'select'
      type: 'select'
      default: []
      restrictions:
        required: true
    }]

  close: ($scope, options) ->
    $state = options.$state
    $state.go 'project.ports'

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    serverURL = $CROSS.settings.serverURL
    tenantId = $CROSS.person.project.id
    form = $scope.form
    netInfo = form.network_id.split(':')
    portParam = {
      network_id: netInfo[0]
      fixed_ips: [{
        subnet_id: netInfo[1]
      }]
      admin_state_up: true
      tenant_id: tenantId
      security_groups: [form.security]
    }
    if form.ip_address
      portParam['fixed_ips'] = [{
        subnet_id: netInfo[1]
        ip_address: form.ip_address
      }]
    $http.post "#{serverURL}/ports", portParam
      .success (data) ->
        toastr.success _("Success create port.")
        $state.go "project.ports", {}, {reload: true}
      .error (err) ->
        if err
          if err.type == 'IpAddressInUse'
            toastr.info _("The IP address has been in use. Failed to create port.")
        else
          toastr.info _("Failed to create port.")
        $state.go "project.ports"

    return

class PortAttachModal extends $cross.Modal
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

  close: ($scope, options) ->
    $state = options.$state
    $state.go 'project.ports'

  portGet: (options, callback) ->
    $http = options.$http
    $q = options.$q
    serverUrl = options.$window.$CROSS.settings.serverURL
    port = $http.get "#{serverUrl}/ports/#{options.portId}"
    server = $http.get "#{serverUrl}/servers/#{options.instanceId}"
    $q.all [port, server]
      .then (values) ->
        callback {portValue: values[0].data, serverValue: values[1].data}


  getLabileData: ($scope, options) ->
    interval = options.$interval
    $state = options.$state
    obj = options.$this
    freshData = interval(() ->
      obj.portGet options, (data) ->
        if data
          if data.portValue.status == 'ACTIVE'
            $scope.$parent.$broadcast 'port-attach-instance', {portId: data.portValue.id, instanceName: data.serverValue.name}
            interval.cancel(freshData)
        else
          interval.cancel(freshData)
    , 5000)

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    obj = options.$this
    serverURL = $CROSS.settings.serverURL
    form = $scope.form
    options.portId = form.port_id
    options.instanceId = form.instance

    attachURL = "#{serverURL}/servers/#{form.instance}/os-interface"
    param = {
      interfaceAttachment: {
        port_id: form.port_id
      }
    }
    $http.post attachURL, param
      .success (data) ->
        toastr.success _("Success attach to instance!")
        obj.getLabileData($scope, options)
        obj.close($scope, options)
      .error (err) ->
        toastr.error _("Failed attach to instance!")
        $state.go 'project.ports', {}, {reload: true}

    return
