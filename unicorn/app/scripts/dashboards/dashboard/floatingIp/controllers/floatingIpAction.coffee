'use strict'

angular.module('Unicorn.dashboard.floatingIp')
  .controller 'dashboard.floatingIp.FloatingIpActionCtrl', ($scope, $http,
  $window, $q, $stateParams, $state) ->
    console.info "Action"

  .controller 'dashboard.floatingIp.FloatingIpBindCtrl', ($scope, $http,
  $window, $q, $stateParams, $state) ->
    floatingIpId = $stateParams.floatingIpId
    $bindModal = (new FloatingIpBindModal()).initial($scope,
      {$state: $state, $http: $http, floatingIpId: floatingIpId, $window: $window})
    $scope.note.modal.save = _("Bind")
    # initial volume list.
    serverUrl = $window.$UNICORN.settings.serverURL
    $http.get "#{serverUrl}/servers"
      .success (servers) ->
        # initial server
        instances = []
        for server in servers.data
          status = server.status.toLowerCase()
          if status == 'error' or status == 'deleting'
            continue
          address = JSON.parse server.addresses
          for add of address
            for ip in address[add]
              if ip['OS-EXT-IPS:type'] != 'fixed'
                continue
              item =
                text: "#{ip['addr']} (#{server['name']})"
                value: "#{server['id']}:#{ip['addr']}"
              instances.push item
        if not instances.length
          instances.push {text: _("No available"), value: -1}
        $scope.modal.fields[0].default = instances
        $scope.form['instance_fix_ip'] = instances[0].value
      .error (err) ->
        toastr.error _("Failed to get servers")
      .finally ->
        $bindModal.clearLoading()


class FloatingIpBindModal extends $unicorn.Modal
  title: "Bind floating ip"
  slug: "bind_floaing_ip"

  fields: ->
    [{
      slug: "instance_fix_ip"
      label: _ "Instance NIC"
      tag: "select"
      restrictions:
        required: true
    }]

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    $window = options.$window
    serverUrl = $UNICORN.settings.serverURL
    form = $scope.form
    split = form['instance_fix_ip']
    if split == -1
      $scope.tips['instance_fix_ip'] = _("No available server")
    dict = split.split ':'
    params = {
      address: options.floatingIpId
      fixed_ip: dict[1]
    }
    params.instanceId = dict[0]
    $unicorn.instanceAction 'addFloatingIp', $http, $window, params, (status, data) ->
      if status == 200
        toastr.success _("Successfully bind floating ip to instance.")
        $state.go 'dashboard.floatingIp', {}, {reload: true}
      else
        message = if data then data.message or '' else ''
        check = /Error: External network .* is not reachable from subnet .*/.test(message)
        if not check
          toastr.error _("Failed to bind floating ip: ") + options.floatingIpId
        else
          toastr.error _(["External network is not reachable, please connect external network using router"])
        options.callback false
