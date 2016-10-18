'use strict'

DEFAULT_MONITOR_PARAM = {
  delay: 30
  timeout: 10
  max_retries: 3
  http_path: '/index.html'
  http_method: 'GET'
  expected_codes: '200,201,202'
}

angular.module('Cross.project.lbaas')
  .controller 'project.lbaas.LBCreateCtr', ($scope, $http,
  $window, $state, $q, $stateParams) ->
    serverURL = $window.$CROSS.settings.serverURL
    createModal = new LBCreateModal()
    createModal.initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state
    })

    $scope.selectedMember = []

    tenantId = $CROSS.person.project.id
    subnets = $http.get "#{serverURL}/subnets?tenant_id=#{tenantId}"
    servers = $http.get "#{serverURL}/servers"
    ports = $http.get "#{serverURL}/ports?tenant_id=#{tenantId}"
    floatingIPs = $http.get "#{serverURL}/os-floating-ips"
    $q.all([subnets, servers, ports, floatingIPs])
      .then (values) ->
        subnetList = values[0].data
        $scope.subnetList = subnetList
        serverList = values[1].data.data
        portList = values[2].data
        fIPList = values[3].data
        subnetOpts = []
        serverMap = {}
        for server in serverList
          serverMap[server.id] = server
        for subnet in subnetList
          if not subnet.enable_dhcp
            continue
          item = {
            text: "#{subnet.name}:#{subnet.cidr}"
            value: subnet.id
          }
          subnetOpts.push item
        if subnetOpts.length == 0
          item = {
            text: _ "None subnet for select"
            value: undefined
          }
          subnetOpts.push item
        availableMembers = []
        for port in portList
          if serverMap[port.device_id]
            instance = serverMap[port.device_id]
            member = {
              name: instance.name
              port: port
            }
            availableMembers.push member
        fIPs = []
        for fIP in fIPList
          if !fIP.fixed_ip
            ip = {
              text: fIP.ip
              value: fIP.id
            }
            fIPs.push ip
        $scope.modal.steps[0].fields[1].default = subnetOpts
        $scope.modal.steps[2].fields[0].default = availableMembers
        if fIPs.length == 0
          ip = {
            text: _ "None available floating ip"
            value: undefined
          }
          fIPs.push ip
        $scope.modal.steps[1].fields[4].default = fIPs

    # Function to control member select.
    $scope.addToSelect = (item) ->
      selected = {
        port_id: item.port.id
        name: item.name
        fixed_ip: item.port.fixed_ips[0].ip_address
        weight: 1
        port: 80
        edit: 'fixed'
      }
      for member in $scope.selectedMember
        if member.port_id == item.port.id
          selected.port = member.port + 1
      $scope.selectedMember.push selected
    $scope.remove = (item, index) ->
      $scope.selectedMember.splice(index, 1)
    $scope.portChange = (item, index) ->
      # TODO(ZhengYue): Handle the input of protocol port,
      # keep the port different of same IP.
      return

    $scope.form.base.max_retries = DEFAULT_MONITOR_PARAM['max_retries']
    $scope.form.base.timeout = DEFAULT_MONITOR_PARAM['timeout']
    $scope.form.base.delay = DEFAULT_MONITOR_PARAM['delay']
    $scope.form.base.path = DEFAULT_MONITOR_PARAM['http_path']
    $scope.form.vip.protocol_port = 80

    # Handle default value of some fields
    # Hide/Display some fields.
    $scope.form.vip.connection_limit = -1
    $scope.$watch 'form', (newVal, oldVal) ->
      if newVal.vip.bind_floatingip
        $scope.modal.steps[1].fields[4].type = ''
        $scope.modal.steps[1].fields[4].restrictions = {required: true}
        $scope.restrictions["vip_floatingip"] = {required: true}
      else
        $scope.modal.steps[1].fields[4].type = 'hidden'
        delete $scope.restrictions["vip_floatingip"]
        $scope.modal.steps[1].fields[4].restrictions = {}
      if newVal.base.monitor_type == 'HTTP' or newVal.base.monitor_type == 'HTTPS'
        if $scope.modal.steps[0].fields[5].type != 'hidden'
          $scope.modal.steps[0].fields[6].type = ''
        else
          $scope.modal.steps[0].fields[6].type = 'hidden'
      else
        $scope.modal.steps[0].fields[6].type = 'hidden'
      res_number = {
        required: true,
        number: true
      }
      if newVal.base.monitor
        if newVal.base.monitor_type == 'HTTP' or newVal.base.monitor_type == 'HTTPS'
          $scope.modal.steps[0].fields[6].type = 'input'
          $scope.modal.steps[0].fields[6].restrictions = {required: true}
          $scope.restrictions["base_path"] = {required: true}
        $scope.modal.steps[0].fields[5].type = 'input'
        $scope.modal.steps[0].fields[7].type = 'input'
        $scope.modal.steps[0].fields[8].type = 'input'
        $scope.modal.steps[0].fields[9].type = 'input'
        $scope.modal.steps[0].fields[9].restrictions = res_number
        $scope.restrictions["base_max_retries"] = res_number
        $scope.modal.steps[0].fields[8].restrictions = res_number
        $scope.restrictions["base_delay"] = res_number
        $scope.modal.steps[0].fields[7].restrictions = res_number
        $scope.restrictions["base_timeout"] = res_number
        $scope.modal.steps[0].fields[5].restrictions = res_number
      else
        $scope.modal.steps[0].fields[5].type = 'hidden'
        $scope.modal.steps[0].fields[6].type = 'hidden'
        $scope.modal.steps[0].fields[7].type = 'hidden'
        $scope.modal.steps[0].fields[8].type = 'hidden'
        $scope.modal.steps[0].fields[9].type = 'hidden'
    , true

  .controller 'project.lbaas.lbActionCtr', ($scope) ->
    return
  .controller 'project.lbaas.vipAction', ($scope, $http,
  $window, $state, $q, $stateParams) ->
    vipEdit = new VIPEditModal()
    vipEdit.initial($scope, {
      $http: $http
      $window: $window
      $state: $state
      $q: $q
    })
    $scope.lbId = $stateParams.LBId
    serverURL = $window.$CROSS.settings.serverURL
    lbURL = "#{serverURL}/lb/pools/#{$scope.lbId}"
    lbaas = $http.get lbURL
    floatingIPs = $http.get "#{serverURL}/os-floating-ips"
    $scope.actionCreateFlag = false

    subnetCallback = (subnetId) ->
      subnetURL = "#{serverURL}/subnets/#{subnetId}"
      $http.get subnetURL
        .success (subnet) ->
          $scope.form.subnet = "#{subnet.name}-#{subnet.cidr}"

    $q.all([lbaas, floatingIPs])
      .then (values) ->
        lb = values[0].data
        $scope.lbName = lb.name
        $scope.lbProtocol = lb.protocol
        fIPList = values[1].data
        floatings = []
        usedIPs = []
        for fIP in fIPList
          if !fIP.fixed_ip
            ip = {
              text: fIP.ip
              value: fIP.id
            }
            floatings.push ip
          else
            usedIPs.push fIP
        if lb.vip_id
          $scope.note.modal.save = _("Update")
          $scope.vipId = lb.vip_id
          # Update current vip
          $scope.form.bind_floatingip = true
          vipURL = "#{serverURL}/lb/vips/#{lb.vip_id}"
          $http.get vipURL
            .success (vip) ->
              $scope.vipPortId = vip.port_id
              subnetCallback(vip.subnet_id)
              if vip.session_persistence
                $scope.form.session_persistence = vip.session_persistence.type
              else
                $scope.form.session_persistence = 'None'
              $scope.form.connection_limit = vip.connection_limit
              $scope.form.protocol_port = vip.protocol_port
              $scope.form.address = vip.address
              for ip in usedIPs
                if ip.fixed_ip == vip.address
                  $scope.currentFIP = {
                    text: ip.ip
                    value: ip.id
                  }
                  floatings.push $scope.currentFIP
                  $scope.modal.fields[6].default = floatings.reverse()
                  $scope.form.floatingip = ip.id
                  matched = true
                  vipEdit.clearLoading()
                  break
              if !matched
                $scope.form.bind_floatingip = false
                if floatings.length == 0
                  floatings = [{
                    text: _ "None available floating ip"
                    value: undefined
                  }]
                $scope.modal.fields[6].default = floatings
                vipEdit.clearLoading()
        else
          # Create new vip
          $scope.note.modal.save = _("Create")
          $scope.actionCreateFlag = true
          $scope.form.protocol_port = 80
          $scope.form.connection_limit = -1
          $scope.modal.fields[0].type = 'input'
          $scope.modal.fields[1].type = 'input'
          $scope.modal.fields[3].type = 'input'
          $scope.modal.fields[6].default = floatings
          tenantId = $CROSS.person.project.id
          subnetURL = "#{serverURL}/subnets?tenant_id=#{tenantId}"
          $http.get subnetURL
            .success (subnets) ->
              subnetList = []
              for subnet in subnets
                item = {
                  text: "#{subnet.name} - #{subnet.cidr}"
                  value: subnet.id
                }
                subnetList.push item
              if subnetList.length == 0
                item = {
                  text: _ "None subnets"
                  value: undefined
                }
              $scope.modal.fields[0] = {
                slug: "subnet"
                label: _("Subnet")
                tag: 'select'
                default: subnetList
              }
              vipEdit.clearLoading()
      , (er) ->
        toastr.error _("Failed to load load balancer.")
        $state.go 'project.lbass'

    $scope.$watch 'form.bind_floatingip', (newVal) ->
      if newVal
        $scope.modal.fields[6].type = ''
        $scope.modal.fields[6].restrictions = {required: true}
        $scope.restrictions["floatingip"] = {required: true}
      else
        $scope.modal.fields[6].type = 'hidden'
        $scope.modal.fields[6].restrictions = {}
        delete $scope.restrictions["floatingip"]
  .controller 'project.lbaas.memberAction', ($scope, $http,
  $window, $state, $q, $stateParams) ->
    $scope.note = {
      cancel: _("Cancel")
      save: _("Update")
    }

    $scope.lbId = $stateParams.LBId
    memberModal = new LBMemberModal()
    memberModal.initial($scope, {
      $state: $state
      $http: $http
      $window: $window
      $q: $q
    })
    serverURL = $window.$CROSS.settings.serverURL
    $scope.selectedMember = []

    tenantId = $CROSS.person.project.id
    servers = $http.get "#{serverURL}/servers"
    ports = $http.get "#{serverURL}/ports?tenant_id=#{tenantId}"
    lb = $http.get "#{serverURL}/lb/pools/#{$scope.lbId}"
    members = $http.get "#{serverURL}/lb/members?pool_id=#{$scope.lbId}"
    $q.all([lb, servers, ports, members])
      .then (values) ->
        pool = values[0].data
        memberList = values[3].data
        $scope.memberList = memberList
        serverList = values[1].data.data
        portList = values[2].data
        serverMap = {}
        for server in serverList
          serverMap[server.id] = server
        fixipMap = {}
        for fixip in memberList
          fixipMap[fixip.address] = fixip
        availableMembers = []
        for port in portList
          if serverMap[port.device_id]
            instance = serverMap[port.device_id]
            member = {
              name: instance.name
              port: port
            }
            availableMembers.push member
            fixedIP = port.fixed_ips[0].ip_address
            if fixipMap[fixedIP]
              member = fixipMap[fixedIP]
              selected = {
                port_id: port.id
                name: instance.name
                fixed_ip: member.address
                weight: member.weight
                port: member.protocol_port
                member_id: member.id
              }
              $scope.selectedMember.push selected
        $scope.avMembers = availableMembers
        memberModal.clearLoading()

    # Function to control member select.
    $scope.addToSelect = (item) ->
      selected = {
        port_id: item.port.id
        name: item.name
        fixed_ip: item.port.fixed_ips[0].ip_address
        weight: 1
        port: 80
      }
      for member in $scope.selectedMember
        if member.port_id == item.port.id
          selected.port = member.port + 1
      $scope.selectedMember.push selected
    $scope.remove = (item, index) ->
      $scope.selectedMember.splice(index, 1)

    $scope.close = () ->
      $state.go 'project.lbaas', {}
    $scope.handle = () ->
      memberUrl = "#{serverURL}/lb/members"
      members = []
      for member in $scope.selectedMember
        if member.member_id
          memberUpdateParam = {
            weight: member.weight
          }
          memberUpdate = $http.put("#{memberUrl}/#{member.member_id}",
          memberUpdateParam)
          members.push memberUpdate
        else
          memberParam = {
            address: member.fixed_ip
            protocol_port: member.port
            weight: member.weight
            admin_state_up: true
            pool_id: $scope.lbId
          }
          memberCreate = $http.post memberUrl, memberParam
          members.push memberCreate
      for member in $scope.memberList
        if $scope.selectedMember.length == 0
          memberDelete = $http.delete "#{memberUrl}/#{member.id}"
          members.push memberDelete
        else
          for newMember in $scope.selectedMember
            if member.id == newMember.member_id
              removed = false
              break
            else
              removed = true
              continue
          if removed
            memberDelete = $http.delete "#{memberUrl}/#{member.id}"
            members.push memberDelete
          else
            continue
      $q.all(members)
        .then (values) ->
          toastr.success _("Success to update members of load balancer.")
          $state.go "project.lbaas", {}
        , (err) ->
          toastr.success _("Failed to update members of load balancer.")
          $state.go "project.lbaas", {}

class LBMemberModal extends $cross.Modal
  title: "Member Manage"
  slug: "member_manage"
  single: true
  modalLoading: true
  fields: ->
    [{
      slug: 'servers'
      label: _ "Available Servers"
      default: []
      type: 'hidden'
    }]

class VIPEditModal extends $cross.Modal
  title: 'VIP Manage'
  slug: 'vip_manage'
  single: true
  modalLoading: true

  fields: ->
    [{
      slug: "subnet"
      label: _("Subnet")
      tag: 'input'
      type: 'disable'
      restrictions:
        required: true
    }, {
      slug: "address"
      label: _("IP Address")
      tag: 'input'
      type: 'disable'
    }, {
      slug: "session_persistence"
      label: _("Session Persistence")
      tag: 'select'
      restrictions:
        required: true
      default: [{
        text: _ 'SOURCE_IP'
        value: 'SOURCE_IP'
      }, {
        text: _ 'HTTP_COOKIE'
        value: 'HTTP_COOKIE'
      }, {
        text: _ 'None'
        value: 'None'
      }]
    }, {
      slug: 'protocol_port'
      label: _ 'Protocol Port'
      tag: 'input'
      type: 'disable'
      restrictions:
        required: true
    }, {
      slug: 'connection_limit'
      label: _ 'Connection Limit'
      tag: 'input'
      restrictions:
        required: true
    }, {
      slug: 'bind_floatingip'
      label: _ "Bind Floating IP"
      tag: 'input'
      type: 'checkbox'
    }, {
      slug: 'floatingip'
      label: _ "Select FloatingIP"
      tag: 'select'
      type: 'hidden'
    }]

  close: ($scope, options) ->
    $state = options.$state
    $state.go 'project.lbaas', {}

  handle: ($scope, options) ->
    $window = options.$window
    $http = options.$http
    $state = options.$state
    $q = options.$q
    serverUrl = $CROSS.settings.serverURL
    form = $scope.form
    updateVip = (url, param) ->
      $http.put url, param
        .success (vip) ->
          toastr.success _("Success update vip.")
          $state.go 'project.lbaas', {}, {reload: true}
        .error (err) ->
          toastr.error _("Failed update vip.")
          $state.go 'project.lbaas', {}, {reload: true}
    if $scope.vipId
      vipURL = "#{serverUrl}/lb/vips/#{$scope.vipId}"
      vipParam = {
        connection_limit: form.connection_limit
        session_persistence:
          type: form.session_persistence
      }
      if form.session_persistence == 'None'
        vipParam.session_persistence = null
      if form.bind_floatingip
        if $scope.currentFIP
          if form.floatingip == $scope.currentFIP.value
            updateVip(vipURL, vipParam)
          else
            # Unbinding current floating ip, bind new one
            oldfloatingURL = "#{serverUrl}/floatingips/#{$scope.currentFIP.value}"
            newfloatingURL = "#{serverUrl}/floatingips/#{form.floatingip}"
            fParam = {
              port_id: null
            }
            bindParam = {
              port_id: $scope.vipPortId
            }

            $http.put oldfloatingURL, fParam
              .success (fip) ->
                $http.put newfloatingURL, bindParam
                  .success (nfip) ->
                    updateVip(vipURL, vipParam)
                  .error (err) ->
                    toastr.error _("Failed to update vip.")
                    $state.go 'project.lbaas', {}, {reload: true}
              .error (err) ->
                toastr.error _("Failed to update vip.")
                $state.go 'project.lbaas', {}, {reload: true}
        else
          newfloatingURL = "#{serverUrl}/floatingips/#{form.floatingip}"
          bindParam = {
            port_id: $scope.vipPortId
          }
          $http.put newfloatingURL, bindParam
            .success (ip) ->
              updateVip(vipURL, vipParam)
            .error (err) ->
              toastr.error _("Failed to update vip.")
              $state.go 'project.lbaas', {}, {reload: true}
      else
        if $scope.currentFIP
          # Unbinding current floating ip
          oldfloatingURL = "#{serverUrl}/floatingips/#{$scope.currentFIP.value}"
          fParam = {
            port_id: null
          }
          $http.put oldfloatingURL, fParam
            .success (fip) ->
              updateVip(vipURL, vipParam)
            .error (err) ->
              toastr.error _("Failed to update vip.")
              $state.go 'project.lbaas', {}, {reload: true}
        else
          updateVip(vipURL, vipParam)
    else
      vipParam = {
        name: $scope.lbName + '_vip'
        subnet_id: form.subnet
        protocol: $scope.lbProtocol
        protocol_port: form.protocol_port
        session_persistence:
          type: form.session_persistence
        connection_limit: form.connection_limit
        admin_state_up: true
        pool_id: $scope.lbId
      }
      if form.session_persistence == 'None'
        vipParam.session_persistence = null
      if form.address
        vipParam.address = form.address
      vipURL = "#{serverUrl}/lb/vips"
      $http.post vipURL, vipParam
        .success (vip) ->
          if form.bind_floatingip
            floatingIPURL = "#{serverUrl}/floatingips/#{form.floatingip}"
            bindParam = {
              port_id: vip.port_id
            }
            $http.put floatingIPURL, bindParam
              .success (bind_res) ->
                toastr.success _("Success to create vip.")
                $state.go 'project.lbaas', {}, {reload: true}
          else
            toastr.success _("Success to create vip.")
            $state.go 'project.lbaas', {}, {reload: true}
        .error (err) ->
          toastr.error _("Failed to create vip.")
          $state.go 'project.lbaas'

class LBCreateModal extends $cross.Modal
  title: 'Create Load Balancer'
  slug: 'lb_create'
  single: false
  steps: ['base', 'vip', 'member']
  modalLoading: false

  step_base: ->
    name: _ "Base Info"
    fields: [{
      slug: "name"
      label: _ "Name"
      tag: 'input'
      restrictions:
        required: true
        len: [4, 25]
    }, {
      slug: "subnet"
      label: _ "Select Subnet"
      tag: "select"
      default: []
      restrictions:
        required: true
    }, {
      slug: "protocol"
      label: _ "Select Protocol"
      tag: "select"
      default: [{
        text: 'HTTP'
        value: 'HTTP'
      }, {
        text: 'HTTPS'
        value: 'HTTPS'
      }, {
        text: 'TCP'
        value: 'TCP'
      }]
      restrictions:
        required: true
    }, {
      slug: 'lb_method'
      label: _ "Select Load Banlence Method"
      tag: 'select'
      default: [{
        text: _ 'ROUND_ROBIN'
        value: 'ROUND_ROBIN'
      }, {
        text: _ 'LEAST_CONNECTIONS'
        value: 'LEAST_CONNECTIONS'
      }, {
        text: _ 'SOURCE_IP'
        value: 'SOURCE_IP'
      }]
      restrictions:
        required: true
    }, {
      slug: 'monitor'
      label: _ "Edit default monitor"
      tag: 'input'
      type: 'checkbox'
    }, {
      slug: 'monitor_type'
      label: _ "Type of health monitor"
      tag: 'select'
      type: 'hidden'
      default: [{
        text: 'PING'
        value: 'PING'
      }, {
        text: 'HTTP'
        value: 'HTTP'
      }, {
        text: 'HTTPS'
        value: 'HTTPS'
      }, {
        text: 'TCP'
        value: 'TCP'
      }]
    }, {
      slug: 'path'
      label: _ "Path"
      tag: 'input'
      type: 'hidden'
    }, {
      slug: 'delay'
      label: _ "Interval"
      tag: 'input'
      restrictions:
        number: true
      type: 'hidden'
    }, {
      slug: 'timeout'
      label: _ "Timeout"
      tag: 'input'
      type: 'hidden'
      restrictions:
        number: true
    }, {
      slug: 'max_retries'
      label: _ "Max retries"
      tag: 'input'
      type: 'hidden'
      restrictions:
        number: true
        range: [1, 10]
    }]

  step_vip: ->
    name: "VIP"
    fields: [{
      slug: 'session_persistence'
      label: _ 'Session Persistence'
      tag: 'select'
      default: [{
        text: _ 'SOURCE_IP'
        value: 'SOURCE_IP'
      }, {
        text: _ 'HTTP_COOKIE'
        value: 'HTTP_COOKIE'
      }, {
        text: _ 'APP_COOKIE'
        value: 'APP_COOKIE'
      }, {
        text: _ 'None'
        value: 'None'
      }]
      restrictions:
        required: true
    }, {
      slug: 'protocol_port'
      label: _ 'Protocol Port'
      tag: 'input'
      restrictions:
        required: true
        number: true
    }, {
      slug: 'connection_limit'
      label: _ 'Connection Limit'
      tag: 'input'
      restrictions:
        required: true
    }, {
      slug: 'bind_floatingip'
      label: _ "Bind Floating IP"
      tag: 'input'
      type: 'checkbox'
    }, {
      slug: 'floatingip'
      label: _ "Select FloatingIP"
      tag: 'select'
      type: 'hidden'
    }]

  step_member: ->
    name: _ "Add Member"
    template: "../views/member.html"
    fields: [{
      slug: 'servers'
      label: _ "Available Servers"
      default: []
    type: 'hidden'
    }]

  handle: ($scope, options) ->
    $window = options.$window
    $http = options.$http
    $state = options.$state
    $q = options.$q
    serverUrl = $CROSS.settings.serverURL
    form = $scope.form
    pool = form.base
    vip = form.vip
    poolParam = {
      admin_state_up: true
      lb_method: pool.lb_method
      name: pool.name
      protocol: pool.protocol
      subnet_id: pool.subnet
    }
    vipParam = {
      name: pool.name + '_vip'
      subnet_id: pool.subnet
      protocol: pool.protocol
      protocol_port: vip.protocol_port
      session_persistence:
        type: vip.session_persistence
      connection_limit: vip.connection_limit
      admin_state_up: true
    }
    if vip.session_persistence == 'None'
      vipParam.session_persistence = null
    if vip.address
      vipParam.address = vip.address
    monitorParam = {
      admin_state_up: true
      delay: DEFAULT_MONITOR_PARAM['delay']
      timeout: DEFAULT_MONITOR_PARAM['timeout']
      type: "PING"
      max_retries: 3
      expected_codes: "200,201,202"
    }
    if pool.monitor
      monitorParam.delay = pool.delay
      monitorParam.timeout = pool.timeout
      monitorParam.max_retries = pool.max_retries
      monitorParam.type = pool.monitor_type
      if pool.monitor_type == "HTTP" or pool.monitor_type == 'HTTPS'
        monitorParam.url_path = pool.path
    poolURL = "#{serverUrl}/lb/pools"
    vipURL = "#{serverUrl}/lb/vips"
    memberUrl = "#{serverUrl}/lb/members"
    monitorUrl = "#{serverUrl}/lb/health_monitors"
    $http.post poolURL, poolParam
      .success (data) ->
        poolId = data.id
        vipParam.pool_id = poolId
        # Create health monitor and assgin to pool
        $http.post monitorUrl, monitorParam
          .success (healthmonitor) ->
            assgin = {
              health_monitor:
                id: healthmonitor.id
            }
            assginUrl = "#{poolURL}/#{poolId}/health_monitors"
            $http.post assginUrl, assgin
              .success (ass) ->
                toastr.success _("Success to add health monitor")
              .error (ass_err) ->
                toastr.error _("Failed to add health monitor")
          .error (health_err) ->
            $log.debug _("Failed to create health monitor")
        # Create VIP and members
        $http.post vipURL, vipParam
          .success (vipData) ->
            if vip.bind_floatingip
              floatingIPURL = "#{serverUrl}/floatingips/#{vip.floatingip}"
              bindParam = {
                port_id: vipData.port_id
              }
              $http.put floatingIPURL, bindParam
                .success (bind_res) ->
                  toastr.success _("Success to bind floating ip")

        members = []
        for member in $scope.selectedMember
          memberParam = {
            address: member.fixed_ip
            protocol_port: member.port
            weight: member.weight
            admin_state_up: true
            pool_id: poolId
          }
          memberCreate = $http.post memberUrl, memberParam
          members.push memberCreate
        $q.all(members)
          .then (values) ->
            toastr.success _("Success to craete load banlancer.")
            $state.go "project.lbaas", {}, {reload: true}
          , (er) ->
            if er.data
              if er.data.type == "IpAddressInUse"
                toastr.error _("Failed at create load banlancer.")
            else
              toastr.error _("Failed at create load banlancer.")
            # Rollback for pool craete
            $http.delete "#{poolURL}/#{poolId}"
            $state.go 'project.lbaas', {}, {reload: true}
      .error (pool_err) ->
        toastr.error _("Failed at create load banlancer.")
        $state.go 'project.lbaas', {}, {reload: true}
