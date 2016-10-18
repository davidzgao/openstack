'use strict'

###*
 # @ngdoc function
 # @name Cross.project.volume:VolumeCreateCtrl
 # @description
 # # VolumeCreateCtrl
 # Controller of the Cross
###
angular.module('Cross.admin.internal_network')
  .controller 'admin.internal_network.InternalNetworkCreateCtr', (
  $scope, $http, $window, $q, $state) ->
    serverUrl = $window.$CROSS.settings.serverURL
    (new NetCreateModal()).initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state})
    # Set default value
    nullProject = [{
    }]
    $cross.listProjects $http, $window, $q, {}, (allProjects) ->
      enabledProjects = [{
        value: 'null'
        text: _ 'None'
      }]
      for pro in allProjects
        if pro.enabled == 'true'
          item = {
            value: pro.id
            text: pro.name
          }
          enabledProjects.push item
      $scope.modal.steps[0].fields[5]['default'] = enabledProjects
      $scope.form['base']['project_id'] = 'null'
    $scope.form['base']['version'] = 'v4'
    $scope.form['advance']['enable_dhcp'] = true
    $scope.form['advance']['share_address'] = false
    $scope.form['advance']['multi_host'] = false


class NetCreateModal extends $cross.Modal
  title: "Create network"
  slug: "network_create"
  single: false
  steps: ['base', 'advance']
  parallel: true

  step_base: ->
    name: _ "Network Base"
    fields:
      [{
        slug: 'label'
        label: _("Name")
        tag: 'input'
        restrictions:
          required: true
          len: [1, 32]
      }, {
        slug: 'version'
        label: _("IP version")
        tag: 'select'
        default: [{
          text: _("IP v4")
          value: 'v4'
        }, {
          text: _("IP v6")
          value: 'v6'
        }]
        type: 'hidden'
      }, {
        slug: 'net_addr'
        label: _("CIDR")
        tag: 'input'
        restrictions:
          required: true
          cidr: true
        placeholder: '192.168.0.1/24'
      }, {
        slug: 'bridge'
        label: _("Bridge Name")
        tag: 'input'
        restrictions:
          required: true
      }, {
        slug: 'bridge_interface'
        label: _("Bridge Interface")
        tag: 'input'
        restrictions:
          required: true
        placeholder: 'eth0'
      }, {
        slug: 'project_id'
        label: _("Project")
        tag: 'select'
        restrictions:
          required: true
      }, {
        slug: 'network_mode'
        label: _('Network Mode')
        tag: 'select'
        default: [{
          text: _('Flat')
          value: 'flat'
        }, {
          text: _('Vlan')
          value: 'vlan'
        }]
      }, {
        slug: 'vlan_num'
        label: _('Vlan Number')
        tag: 'input'
        placeholder: _ 'The number of specific vlan'
        type: 'hidden'
      }]

  step_advance: ->
    name: _ "Network Advance"
    fields:
      [{
        slug: 'gateway'
        label: _('Gateway')
        tag: 'input'
        restrictions:
          required: false
        placeholder: _('The gateway address')
      }, {
        slug: 'dhcp_server'
        label: _('DHCP Server')
        tag: 'input'
        restrictions:
          required: false
        placeholder: _('The DHCP server address')
      }, {
        slug: 'dns1'
        label: _('DNS Server')
        tag: 'input'
        restrictions:
          required: false
        placeholder: _('The DNS server address')
      }, {
        slug: 'enable_dhcp'
        label: _('Enable DHCP')
        tag: 'input'
        type: 'checkbox'
      }, {
        slug: 'allocation_pool'
        label: _('Allocation Range')
        tag: 'input'
        placeholder: _('Start and end address, like: 192.168.0.110,192.168.0.120')
      }, {
        slug: 'multi_host'
        label: _('Multi Host')
        tag: 'input'
        type: 'checkbox'
      }, {
        slug: 'share_address'
        label: _('Share Address')
        tag: 'input'
        type: 'hidden'
      }, {
        slug: 'mtu'
        label: _('MTU')
        tag: 'input'
        restrictions:
          required: false
        placeholder: _(['Default value is %s', $CROSS.settings.mtu])
      }]

  validator: ($scope, options) ->
    rs = super($scope, options)
    if not rs
      return false
    step = options.step
    field = options.field
    if step == 'base' and field == 'network_mode'
      if $scope.form['base']['network_mode'] == 'flat'
        $scope.modal.steps[0].fields[7].type = 'hidden'
        $scope.modal.steps[0].fields[7].restrictions = {required: false}
        delete $scope.restrictions['base_vlan_num']
      else
        $scope.modal.steps[0].fields[7].type = ''
        $scope.modal.steps[0].fields[7].restrictions = {required: true}
        $scope.restrictions['base_vlan_num'] = {required: true}

    if step == 'advance' and field == 'multi_host'
      if $scope.form['advance']['multi_host']
        $scope.modal.steps[1].fields[6].type = 'checkbox'
      else
        $scope.modal.steps[1].fields[6].type = 'hidden'

    return rs

  handle: ($scope, options) ->
    $http = options.$http
    serverUrl = $CROSS.settings.serverURL
    form = $scope.form
    $state = options.$state
    base = form.base
    advance = form.advance
    # NOTE(ZhengYue): To conflict avoidance between bridge name and
    # default interface name in compute node, so add 'br-' if
    # bridge name start with 'vlan'.
    bridge_name = base['bridge']
    lower_bridge_name = bridge_name.toLowerCase()
    if lower_bridge_name.indexOf('vlan') == 0
      base['bridge'] = "br-#{bridge_name}"
    if base['version'] == 'v4'
      base['cidr'] = base['net_addr']
    else
      base['cidr_v6'] = base['net_addr']
    if base['project'] == 'null'
      delete base.project
    if base['network_mode'] == 'vlan'
      base['vlan'] = base['vlan_num']
      delete base['vlan_num']
    else
      delete base['vlan_num']
    if not advance['multi_host']
      advance['share_address'] = false
    if base['project_id'] == 'null'
      delete base['project_id']
    delete base.version
    delete base.net_addr
    delete base.network_mode
    if advance.allocation_pool
      pool = advance.allocation_pool
      if pool.indexOf(',')
        poolArr = pool.split(',')
        advance.allowed_start = poolArr[0]
        advance.allowed_end = poolArr[1]
    delete advance.allocation_pool
    if not advance.mtu
      advance.mtu = $CROSS.settings.mtu or 1500
    data = $.extend({}, form.base, form.advance)
    if not data.gateway
      delete data.gateway
    if not data.dns1
      delete data.dns1
    if not data.dhcp_server
      delete data.dhcp_server
    $http.post "#{serverUrl}/os-networks", data
      .success ->
        toastr.success _("Successfully to create network.")
        $state.go 'admin.internal_network', {}, {reload: true}
      .error (error)->
        toastr.error _("Failed to create network.")
        $state.go 'admin.internal_network', {}, {reload: true}
