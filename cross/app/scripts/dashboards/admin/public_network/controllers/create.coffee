'use strict'

###*
 # @ngdoc function
 # @name Cross.project.volume:VolumeCreateCtrl
 # @description
 # # VolumeCreateCtrl
 # Controller of the Cross
###
angular.module('Cross.admin.public_network')
  .controller 'admin.public_network.PublicNetworkCreateCtr', ($scope, $http, $window, $q,
                                         $state, $interval, $templateCache,
                                         $compile, $animate) ->
    serverUrl = $window.$CROSS.settings.serverURL
    (new NetCreateModal()).initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state})


class NetCreateModal extends $cross.Modal
  title: "Create floating ip pool"
  slug: "floating_ip_pool_create"
  single: true

  fields: ->
    interfaces = [{
      text: 'eth0'
      value: 'eth0'
    }, {
      text: 'eth1'
      value: 'eth1'
    }]
    if $CROSS.settings.interfaces
      interfaces = []
      for itf in $CROSS.settings.interfaces
        item =
          text: itf
          value: itf
        interfaces.push item
    [{
      slug: 'name'
      label: _("Name")
      tag: 'input'
      restrictions:
        required: true
        len: [1, 32]
    }, {
      slug: 'net_addr'
      label: _("CIDR")
      tag: 'input'
      restrictions:
        required: true
        cidr: true
    }, {
      slug: 'interface'
      label: _("Interface")
      tag: 'select'
      default: interfaces
    }]

  handle: ($scope, options) ->
    $http = options.$http
    serverUrl = $CROSS.settings.serverURL
    form = $scope.form
    $state = options.$state
    data =
      ip_range: form['net_addr']
    if form['interface']
      data['interface'] = form['interface']
    if form['name']
      data['pool'] = form['name']

    $http.post "#{serverUrl}/os-floating-ips-bulk", data
      .success ->
        options.callback false
        $state.go 'admin.public_network', {}, {reload: true}
      .error (error) ->
        toastr.error _("Failed to create floating ip pool.")
        options.callback false
