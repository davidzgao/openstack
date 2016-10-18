'use strict'

angular.module('Cross.admin.network')
  .controller 'admin.network.NetworkCreateCtr', ($scope, $http,
  $window, $state, $q, $stateParams) ->
    serverURL = $window.$CROSS.settings.serverURL
    createSubnet = () ->
      $scope.subnetMap = {}
      subnets = $http.get "#{serverURL}/subnets"
      $q.all([subnets])
        .then (values) ->
          for subnet in values[0].data
            if !$scope.subnetMap[subnet.tenant_id]
              $scope.subnetMap[subnet.tenant_id] = [subnet.name]
            else
              $scope.subnetMap[subnet.tenant_id].push subnet.name
      createModal = new SubnetCreateModal
      createModal.initial($scope, {
        $window: $window
        $q: $q
        $http: $http
        $state: $state
      })
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
              disable: false
            }, {
              range: {
                min: 0
                max: 255
              }
              disable: false
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

      $scope.ipSelected = 0
      $scope.selectChange = (index) ->
        if index != $scope.ipSelected
          $scope.ipSelected = index
      $scope.modal.steps[0].fields[2].default = ipsets

      $http.get "#{serverURL}/networks"
        .success (data) ->
          items = []
          for network in data
            item = {
              text: network.name
              value: "#{network.id}@#{network.tenant_id}"
            }
            items.push item
          $scope.modal.steps[0].fields[1].default = items
          $scope.form['network'] = items[0]
      $scope.form['enable_dhcp'] = true
    createNetwork = () ->
      $scope.networkMap = {}
      $scope.subnetMap = {}
      networks = $http.get "#{serverURL}/networks"
      subnets = $http.get "#{serverURL}/subnets"
      $q.all([networks, subnets])
        .then (values) ->
          for network in values[0].data
            if !$scope.networkMap[network.tenant_id]
              $scope.networkMap[network.tenant_id] = [network.name]
            else
              $scope.networkMap[network.tenant_id].push network.name
          for subnet in values[1].data
            if !$scope.subnetMap[subnet.tenant_id]
              $scope.subnetMap[subnet.tenant_id] = [subnet.name]
            else
              $scope.subnetMap[subnet.tenant_id].push subnet.name
      createModal = new NetworkCreateModal
      createModal.initial($scope, {
        $window: $window
        $q: $q
        $http: $http
        $state: $state
      })
      $cross.listProjects $http, $window, $q, {}, (projects) ->
        items = []
        for project in projects
          item = {
            text: project.name
            value: project.id
          }
          items.push item
          $scope.modal.steps[0].fields[1].default = items

      $http.get "#{serverURL}/networks?router:external=true"
        .success (networks) ->
          if networks.length > 0
            $scope.modal.steps[0].fields[3].type = 'hidden'

      network_types = $CROSS.settings.default_network_types
      network_types = network_types.split(',')
      types = []
      for type in network_types
        item = {
          text: type.toUpperCase()
          value: type
        }
        types.push item

      $scope.modal.steps[0].fields[2].default = types
      $scope.form.network.network_type = types[0].value
      $scope.$watch 'form', (newVal) ->
        subnetStep = $scope.modal.steps[1]
        subName = subnetStep.fields[1]
        subCidr = subnetStep.fields[2]
        if newVal.subnet['create_subnet']
          subName.restrictions = {
            func: ($scope, val) ->
              if $scope.form.network.project
                subnetsOfProject = $scope.subnetMap[$scope.form.network.project] || []
                if val in subnetsOfProject
                  return _ "This value has been took up."
            required: true,
            len: [1, 32]
          }
          subCidr.restrictions = {
            required: true,
            cidr: true
          }
          $scope.restrictions["subnet_#{subName.slug}"] = subName.restrictions
          $scope.restrictions["subnet_#{subCidr.slug}"] = subCidr.restrictions
        else
          subName.restrictions = {}
          subCidr.restrictions = {}
          delete $scope.restrictions["subnet_#{subName.slug}"]
          delete $scope.restrictions["subnet_#{subCidr.slug}"]
          $scope.form.advance['enable_dhcp'] = false
      , true
    if $state.params.tab == 'subnet'
      createSubnet()
    else
      createNetwork()
  .controller 'admin.network.networkActionCtr', ($scope) ->
    return
  .controller 'admin.network.createSubAction', ($scope, $http,
  $window, $state, $q, $stateParams) ->
    $scope.subnetsName = []
    networkId = $stateParams.nId
    serverURL = $window.$CROSS.settings.serverURL
    networks = $http.get "#{serverURL}/networks"
    subnets = $http.get "#{serverURL}/subnets"
    $q.all([networks, subnets])
      .then (values) ->
        for network in values[0].data
          if network.id == networkId
            tenantId = network.tenant_id
            break
        for subnet in values[1].data
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
    $http.get "#{serverURL}/networks/#{networkId}"
      .success (data) ->
        tenantId = data.tenant_id
        $scope.form.subnet['tenant_id'] = tenantId
      .error (err) ->
        $state.go '^'
    $scope.form.subnet['network_id'] = networkId
  .controller 'admin.network.attachAction', ($scope, $http,
  $window, $state, $q, $stateParams) ->
    serverURL = $window.$CROSS.settings.serverURL
    subnetId = $stateParams.nId
    modal = new RelRouterModal
    modal.initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state
      $stateParams: $stateParams
    })
    $scope.form['subnet'] = subnetId
    $http.get "#{serverURL}/routers"
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
  single: false
  parallel: true
  steps: ['subnet', 'advance']

  step_subnet: ->
    name: _("Subnet Info")
    fields: [{
      slug: 'network_id'
      label: _("Network")
      tag: 'input'
      type: 'hidden'
    }, {
      slug: 'tenant_id'
      label: _("tenant")
      tag: 'input'
      type: 'hidden'
    }, {
      slug: 'subnet_name'
      label: _("Subnet Name")
      tag: 'input'
      restrictions:
        func: ($scope, val) ->
          if val in $scope.subnetsName
            return _ "This value has been took up."
        required: true,
        len: [1, 32]
    }, {
      slug: 'ip_address'
      label: _("CIDR")
      tag: 'input'
      restrictions:
        required: true
        cidr: true
    }, {
      slug: 'ip_version'
      label: _("IP Version")
      tag: 'select'
      default: [{
        text: 'IPv4'
        value: 4
      }, {
        text: 'IPv6'
        value: 6
      }]
    }, {
      slug: 'gateway_ip'
      label: _("Gateway IP")
      tag: 'input'
    }, {
      slug: 'no_gateway'
      label: _("Disable Gateway")
      tag: 'input'
      type: 'checkbox'
    }]

  step_advance: ->
    name: _("Advance Config")
    fields: [{
      slug: 'enable_dhcp'
      label: _("Enable DHCP")
      tag: 'input'
      type: 'checkbox'
    }, {
      slug: 'dns_nameservers'
      label: _("DNS name servers")
      tag: 'textarea'
      rows: 3
      placeholder: _("DNS servers for subnet, separate by commas.")
    }, {
      slug: 'allocation_pools'
      label: _("Allocation Pool")
      tag: 'textarea'
      rows: 3
      placeholder: _("Start and end address, each row of a record. Like: 192.168.0.2,192.168.0.6")
    }, {
      slug: 'host_routes'
      label: _("Host Routes")
      tag: 'textarea'
      rows: 3
      placeholder: _("Additional routes for host, destination CIDR and nexthop, each row of a record. Like: 192.168.200.0/24,10.56.1.254")
    }]

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    serverURL = $CROSS.settings.serverURL
    subnetURL = "#{serverURL}/subnets"
    form = $scope.form
    form_subnet = form.subnet
    if form.advance.dns_nameservers
      nameservers_tmp = form.advance.dns_nameservers.replace(/\s+/g, '')
      nameservers = nameservers_tmp.split(',')
    else
      nameservers = $CROSS.settings.defaut_nameservers ||\
      ['8.8.8.8']
    subnetParam = {
      name: form_subnet.subnet_name
      ip_version: form_subnet.ip_version
      cidr: form_subnet.ip_address
      network_id: form_subnet.network_id
      enable_dhcp: form.advance.enable_dhcp | false
      dns_nameservers: nameservers
      tenant_id: form_subnet.tenant_id
    }
    # Cherry the pool and route from params
    advance = form.advance
    if advance.allocation_pools
      pools = []
      rangeArray = advance.allocation_pools.split('\n')
      for range in rangeArray
        range_tmp = range.replace(/\s+/g, '')
        aRange = range_tmp.split(',')
        pools.push({start: aRange[0], end: aRange[1]})
      subnetParam['allocation_pools'] = pools
    if advance.host_routes
      routes = []
      routesArray = advance.host_routes.split('\n')
      for route in routesArray
        route_tmp = route.replace(/\s+/g, '')
        aRoute = route_tmp.split(',')
        routes.push({destination: aRoute[0], nexthop: aRoute[1]})
      subnetParam['host_routes'] = routes
    if form.subnet.gateway_ip
      subnetParam['gateway_ip'] = form.subnet.gateway_ip
    if form.subnet.no_gateway
      delete subnetParam['gateway_ip']
    $http.post subnetURL, subnetParam
      .success (subnet) ->
        $state.go "admin.network", {}, {reload: true}
        toastr.success _("Success to create subnet.")
        return true
      .error (err) ->
        $state.go "admin.network", {}, {reload: true}
        toastr.error _("Failed to create subnet.")
        return true
    return true

  close: ($scope, options) ->
    $state = options.$state
    $state.go "admin.network"

class NetworkCreateModal extends $cross.Modal
  title: 'Create Network'
  slug: 'network_create'
  single: false
  parallel: true
  steps: ['network', 'subnet', 'advance']

  step_network: ->
    name: _("Network Info")
    fields: [{
      slug: 'name'
      label: _("Name")
      tag: 'input'
      restrictions:
        func: ($scope, val) ->
          if $scope.form.network.project
            networksOfProject = $scope.networkMap[$scope.form.network.project] || []
            if val in networksOfProject
              return _ "This value has been took up."
        required: true
        len: [1, 32]
    }, {
      slug: 'project'
      label: _("Project")
      tag: 'select'
      default: []
      restrictions:
        # This func is used to test network's name whether only
        # one under the same tenant.
        func: ($scope, val) ->
          if $scope.form.network.project
            networksOfProject = $scope.networkMap[$scope.form.network.project] || []
            subnetsOfProject = $scope.subnetMap[$scope.form.network.project] || []
            if $scope.form.network.name in networksOfProject
              $scope.tips['network']['name'] = _ "This value has been took up."
            else
              $scope.tips['network']['name'] = ""

            if $scope.form.subnet.subnet_name in subnetsOfProject
              $scope.tips['subnet']['subnet_name'] = _ "This value has been took up."
            else
              $scope.tips['subnet']['subnet_name'] = ""
          else
            $scope.tips['network']['name'] = ""
            $scope.tips['subnet']['subnet_name'] = ""

          return

        required: true
    }, {
      slug: 'network_type'
      label: _("Network Type")
      tag: 'select'
      default: [],
      restrictions:
        required: true
    }, {
      slug: 'public'
      label: _("Public Network")
      tag: 'input'
      type: 'checkbox'
    }, {
      slug: 'is_shared'
      label: _("Is Shared")
      tag: 'input'
      type: 'checkbox'
    }]

  step_subnet: ->
    name: _("Subnet Info")
    fields: [{
      slug: 'create_subnet'
      label: _("Create Subnet")
      tag: 'input'
      type: 'checkbox'
    }, {
      slug: 'subnet_name'
      label: _("Subnet Name")
      tag: 'input'
    }, {
      slug: 'ip_address'
      label: _("CIDR")
      tag: 'input'
    }, {
      slug: 'ip_version'
      label: _("IP Version")
      tag: 'select'
      default: [{
        text: 'IPv4'
        value: 4
      }, {
        text: 'IPv6'
        value: 6
      }]
    }, {
      slug: 'gateway_ip'
      label: _("Gateway IP")
      tag: 'input'
    }, {
      slug: 'no_gateway'
      label: _("Disable Gateway")
      tag: 'input'
      type: 'checkbox'
    }]

  step_advance: ->
    name: _("Advance Config")
    fields: [{
      slug: 'enable_dhcp'
      label: _("Enable DHCP")
      tag: 'input'
      type: 'checkbox'
    }, {
      slug: 'dns_nameservers'
      label: _("DNS name servers")
      tag: 'textarea'
      rows: 3
      placeholder: _("DNS servers for subnet, separate by commas.")
    }, {
      slug: 'allocation_pools'
      label: _("Allocation Pool")
      tag: 'textarea'
      rows: 3
      placeholder: _("Start and end address, each row of a record. Like: 192.168.0.2,192.168.0.6")
    }, {
      slug: 'host_routes'
      label: _("Host Routes")
      tag: 'textarea'
      rows: 3
      placeholder: _("Additional routes for host, destination CIDR and nexthop, each row of a record. Like: 192.168.200.0/24,10.56.1.254")
    }]

  handle: ($scope, options) ->
    $http = options.$http
    $state = options.$state
    serverURL = $CROSS.settings.serverURL
    form = $scope.form
    networkParam = {
      name: form.network.name
      admin_state_up: true
      tenant_id: form.network.project
      "router:external": form.network.public | false
      shared: form.network.is_shared | false
      "provider:network_type": form.network.network_type
    }
    networkURL = "#{serverURL}/networks"
    subnetURL = "#{serverURL}/subnets"
    $http.post networkURL, networkParam
      .success (data) ->
        form_subnet = form.subnet
        if form_subnet.create_subnet
          if form_subnet.dns_nameservers
            nameservers_tmp = form_subnet.dns_nameservers.replace(/\s+/g, '')
            nameservers = nameservers_tmp.split(',')
          else
            nameservers = $CROSS.settings.defaut_nameservers ||\
            ['8.8.8.8']
          subnetParam = {
            name: form_subnet.subnet_name
            ip_version: form_subnet.ip_version
            cidr: form_subnet.ip_address
            network_id: data.id
            tenant_id: form.network.project
            enable_dhcp: form.advance.enable_dhcp | false
            dns_nameservers: nameservers
          }
          # Cherry the pool and route from params
          advance = form.advance
          if advance.allocation_pools
            pools = []
            rangeArray = advance.allocation_pools.split('\n')
            for range in rangeArray
              range_tmp = range.replace(/\s+/g, '')
              aRange = range_tmp.split(',')
              pools.push({start: aRange[0], end: aRange[1]})
            subnetParam['allocation_pools'] = pools
          if advance.host_routes
            routes = []
            routesArray = advance.host_routes.split('\n')
            for route in routesArray
              route_tmp = route.replace(/\s+/g, '')
              aRoute = route_tmp.split(',')
              routes.push({destination: aRoute[0], nexthop: aRoute[1]})
            subnetParam['host_routes'] = routes
          if form.subnet.gateway_ip
            subnetParam['gateway_ip'] = form.subnet.gateway_ip
          if form.subnet.no_gateway
            delete subnetParam['gateway_ip']
          $http.post subnetURL, subnetParam
            .success (subnet) ->
              toastr.success _("Success create netowrk!")
              $state.go "admin.network", {}, {reload: true}
              return true
        else
          toastr.success _("Success create netowrk!")
          $state.go "admin.network", {}, {reload: true}
      .error (err) ->
        toastr.error _ "Error at create network."
        $state.go "admin.network", {}, {reload: true}

class SubnetCreateModal extends $cross.Modal
  title: 'Create Subnet'
  slug: 'subnet_create'
  single: false
  parallel: true
  steps: ['subnet', 'advance']

  step_subnet: ->
    name: _("Subnet Info")
    fields: [{
      slug: 'subnet_name'
      label: _("Subnet Name")
      tag: 'input'
      restrictions:
        func: ($scope, val) ->
          if $scope.form.subnet.network
            networkInfo = $scope.form.subnet.network
            tenantId = networkInfo.slice networkInfo.indexOf('@') + 1
            if val in $scope.subnetMap[tenantId]
              return _ "This value has been took up."
        required: true
        len: [1, 32]
    }, {
      slug: 'network'
      label: _("Select Network")
      tag: 'select'
      default: []
      restrictions:
        func: ($scope, val) ->
          if $scope.form.subnet.network
            networkInfo = $scope.form.subnet.network
            tenantId = networkInfo.slice networkInfo.indexOf('@') + 1
            if $scope.form.subnet.subnet_name in $scope.subnetMap[tenantId]
              $scope.tips['subnet']['subnet_name'] = _ "This value has been took up."
            else
              $scope.tips['subnet']['subnet_name'] = _ ""
          return
        required: true
    }, {
      slug: 'ip_address'
      label: _("CIDR")
      tag: 'ipinput'
      ipSelect: true
      default: []
    }, {
      slug: 'ip_version'
      label: _("IP Version")
      tag: 'select'
      default: [{
        text: 'IPv4'
        value: 4
      }, {
        text: 'IPv6'
        value: 6
      }]
    }, {
      slug: 'gateway_ip'
      label: _("Gateway IP")
      tag: 'input'
    }, {
      slug: 'no_gateway'
      label: _("Disable Gateway")
      tag: 'input'
      type: 'checkbox'
    }]

  step_advance: ->
    name: _("Advance Config")
    fields: [{
      slug: 'enable_dhcp'
      label: _("Enable DHCP")
      tag: 'input'
      type: 'checkbox'
    }, {
      slug: 'dns_nameservers'
      label: _("DNS name servers")
      tag: 'textarea'
      rows: 3
      placeholder: _("DNS servers for subnet, separate by commas.")
    }, {
      slug: 'allocation_pools'
      label: _("Allocation Pool")
      tag: 'textarea'
      rows: 3
      placeholder: _("Start and end address, each row of a record. Like: 192.168.0.2,192.168.0.6")
    }, {
      slug: 'host_routes'
      label: _("Host Routes")
      tag: 'textarea'
      rows: 3
      placeholder: _("Additional routes for host, destination CIDR and nexthop, each row of a record. Like: 192.168.200.0/24,10.56.1.254")
    }]

  fields: ->
    [{
      slug: 'name'
      label: _('Name')
      tag: 'input'
      restrictions:
        required: true
        len: [1, 32]
    }, {
      slug: 'network'
      label: _("Select Network")
      tag: 'select'
      default: []
    }, {
      slug: 'ip_address'
      label: _("CIDR")
      tag: 'input'
      restrictions:
        required: true
        cidr: true
    }, {
      slug: 'gateway_ip'
      label: _("Gateway IP")
      tag: 'input'
    }, {
      slug: 'enable_dhcp'
      label: _("Enable DHCP")
      tag: 'input'
      type: 'checkbox'
    }, {
      slug: 'dns_nameservers'
      label: _("DNS name servers")
      tag: 'textarea'
    }]

  validator: ($scope, options) ->
    res = super($scope, options)
    field = options.field
    ip = $scope.modal.steps[0].fields[2].default[$scope.ipSelected]
    $scope.form.subnet.ip_address = ip.value
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
    form = $scope.form
    networkTrunk = form.subnet.network.split('@')
    networkId = networkTrunk[0]
    tenantId = networkTrunk[1]
    form_subnet = form.subnet
    if form.advance.dns_nameservers
      nameservers_tmp = form.advance.dns_nameservers.replace(/\s+/g, '')
      nameservers = nameservers_tmp.split(',')
    else
      nameservers = $CROSS.settings.defaut_nameservers ||\
      ['8.8.8.8']
    subnetParam = {
      name: form_subnet.subnet_name
      ip_version: form_subnet.ip_version
      cidr: form_subnet.ip_address
      network_id: networkId
      tenant_id: tenantId
      enable_dhcp: form.advance.enable_dhcp | false
      dns_nameservers: nameservers
    }
    # Cherry the pool and route from params
    advance = form.advance
    if advance.allocation_pools
      pools = []
      rangeArray = advance.allocation_pools.split('\n')
      for range in rangeArray
        range_tmp = range.replace(/\s+/g, '')
        aRange = range_tmp.split(',')
        pools.push({start: aRange[0], end: aRange[1]})
      subnetParam['allocation_pools'] = pools
    if advance.host_routes
      routes = []
      routesArray = advance.host_routes.split('\n')
      for route in routesArray
        route_tmp = route.replace(/\s+/g, '')
        aRoute = route_tmp.split(',')
        routes.push({destination: aRoute[0], nexthop: aRoute[1]})
      subnetParam['host_routes'] = routes
    if form.subnet.gateway_ip
      subnetParam['gateway_ip'] = form.subnet.gateway_ip
    if form.subnet.no_gateway
      delete subnetParam['gateway_ip']
    subnetURL = "#{serverURL}/subnets"
    $http.post subnetURL, subnetParam
      .success (data) ->
        toastr.success _("Success to create subnet.")
        $state.go "admin.network", {tab: 'subnet'}, {reload: true}
      .error (err) ->
        toastr.error _ "Error at create network."
        $state.go "admin.network", {tab: 'subnet'}, {reload: true}

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

    $state.go 'admin.network', {tab: 'subnet'}, {reload: true}
    return true

  close: ($scope, options) ->
    $state = options.$state
    $state.go 'admin.network'
