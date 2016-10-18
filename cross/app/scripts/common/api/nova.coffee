'use strict'

instanceAttrs = ['id', 'name', 'status', 'OS-EXT-SRV-ATTR:hypervisor_hostname'
                 'flavor', 'tenant_id', 'user_id', 'addresses',
                 'project_name', 'user_name', 'vcpus', 'ram', 'disk',
                 'OS-EXT-STS:task_state', 'created', 'image',
                 'security_groups', 'metadata']

###
Simple wrapper around nova server API
###
class $cross.Server extends $cross.APIResourceWrapper
  constructor: (instance, attrs) ->
    super instance, attrs

###
Simple wrapper around nova flavor API
###
class $cross.Flavor extends $cross.APIResourceWrapper
  constructor: (flavor, attrs) ->
    super flavor, attrs

###
List server that contain base instance info.
###
$cross.listServers = ($http, $window, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  requestData =
    url: "#{serverURL}/servers"
    method: 'GET'

  $http requestData
    .success (instances, status, headers) ->
      serverList = []
      for instance in instances.data
        server = new $cross.Server(instance, instanceAttrs)
        serverList.push server.getObject(server)
      callback serverList

getDefaultCluster = (hosts) ->
  # TODO(ZhengYue): Take it into config file
  _QEMU = "QEMU"
  _VMWARE = "VMware vCenter Server"

  defaultCluster = {
    hosts: hosts
    id: 0
    name: 'default'
    metadata:
      shared_storage: 'N/A'
    hypervisor_type: _QEMU
  }
  return defaultCluster

$cross.listClusters = ($http, $window, $q, callback) ->
  serverUrl = $window.$CROSS.settings.serverURL
  clustersParams = "/os-aggregates"
  clusters = $http.get("#{serverUrl}#{clustersParams}")
    .then (response) ->
      return response.data
  hypervisorsParams = "/os-hypervisors"
  hypervisors = $http.get("#{serverUrl}#{hypervisorsParams}")
    .then (response) ->
      return response.data

  $q.all([clusters, hypervisors])
    .then (values) ->
      clusterList = values[0]
      compute_nodes = values[1]
      nodesMap = {}
      for node in compute_nodes
        nodesMap[node.hypervisor_hostname] = node
      if clusterList.length == 0
        defaultCluster = getDefaultCluster compute_nodes
        clusterList.push defaultCluster
      for cluster in clusterList
        cluster.compute_nodes = []
        for host in cluster.hosts
          if nodesMap[host]
            cluster.compute_nodes.push nodesMap[host]
      callback clusterList
    , (err) ->
      callback []

$cross.listHosts = ($http, $window, $q, callback) ->
  serverUrl = $window.$CROSS.settings.serverURL
  hypervisorsParams = "/os-hypervisors/detail"
  servicesParams = "/os-services?binary=nova-compute"
  hypervisors = $http.get("#{serverUrl}#{hypervisorsParams}")
    .then (response) ->
      return response.data
  services = $http.get("#{serverUrl}#{servicesParams}")
    .then (response) ->
      return response.data

  $q.all([hypervisors, services])
    .then (values) ->
      hosts = values[0]
      services = values[1]

      servicesMap = {}
      for service in services
        servicesMap[service.host] = {
          state: service.state
          status: service.status
        }
      for host in hosts
        if host.hypervisor_type == 'QEMU'
          hostService = host.service
          host.service.state = servicesMap[hostService.host].state
          host.service.status = servicesMap[hostService.host].status
      callback hosts
    , (err) ->
      callback []

$cross.getHost = ($http, $window, hostId, callback) ->
  serverUrl = $window.$CROSS.settings.serverURL
  hypervisorsParams = "/os-hypervisors/#{hostId}"
  $http.get "#{serverUrl}#{hypervisorsParams}"
    .success (data, status, headers) ->
      callback data
    .error (data, status, headers) ->
      toastr.error(_("Failed get compute node info!"))

$cross.enableService = ($http, $window, params, callback) ->
  serverUrl = $window.$CROSS.settings.serverURL
  servicesParams = "/os-services/enable"
  $http.put "#{serverUrl}#{servicesParams}", params
    .success (data, status, headers) ->
      callback status
      toastr.success _("Success to enable compute node: ") + params.host
    .error (data, status, headers) ->
      callback status
      toastr.error _("Failed to enable compute node: ") + params.host

$cross.disableService = ($http, $window, params, callback) ->
  serverUrl = $window.$CROSS.settings.serverURL
  servicesParams = "/os-services/disable"
  $http.put "#{serverUrl}#{servicesParams}", params
    .success (data, status, headers) ->
      callback status
      toastr.success _("Success to disable compute node: ") + params.host
    .error (data, status, headers) ->
      callback status
      toastr.error _("Failed to disable compute node: ") + params.host

$cross.deleteService = ($http, $window, serviceId, callback) ->
  serverUrl = $window.$CROSS.settings.serverURL
  servicesParams = "/os-services/#{serviceId}"
  $http.delete "#{serverUrl}#{servicesParams}"
    .success (data, status, headers) ->
      callback data
      toastr.success _("Success delete the compute node!")
    .error (data, status, headers) ->
      callback data
      toastr.error _("Failed delete the compute node!")

$cross.getAvailableHosts = ($http, $window, $q, clusterId, callback) ->
  serverUrl = $window.$CROSS.settings.serverURL
  clustersParams = "/os-aggregates"
  clusters = $http.get("#{serverUrl}#{clustersParams}")
    .then (response) ->
      return response.data
  hypervisorsParams = "/os-hypervisors"
  hypervisors = $http.get("#{serverUrl}#{hypervisorsParams}")
    .then (response) ->
      return response.data

  clusteredList = []
  availableList = []
  hostInCurrent = []
  selectedHosts = []
  $q.all([clusters, hypervisors])
    .then (values) ->
      clusterList = values[0]
      computeNodes = values[1]
      for cluster in clusterList
        for node in cluster.hosts
          clusteredList.push node
          if clusterId
            if clusterId == String(cluster.id)
              hostInCurrent.push node

      for host in computeNodes
        isUsed = false
        availHost =
          {
            id: host.id
            name: host.hypervisor_hostname
          }
        if host.hypervisor_hostname in clusteredList
          isUsed = true
          if host.hypervisor_hostname in hostInCurrent
            selectedHosts.push availHost
        if isUsed == false
          availableList.push availHost

      callback availableList, selectedHosts

$cross.getCluster = ($http, $window, clusterId, callback) ->
  serverUrl = $window.$CROSS.settings.serverURL
  clusterParams = "/os-aggregates/#{clusterId}"
  $http.get("#{serverUrl}#{clusterParams}")
    .success (data, status, headers) ->
      callback data
    .error (data, status, headers) ->
      toastr.error _ "Failed to get cluster info."

$cross.updateClusterNodes = ($http, $window, options, callback) ->
  serverUrl = $window.$CROSS.settings.serverURL
  clusterParams = "#{serverUrl}/os-aggregates/#{options.clusterId}/action"
  params = options.params
  $http.post clusterParams, params
    .success (data, status, headers) ->
      if callback
        callback data

$cross.updateCluster = ($http, $window, clusterId, options, callback) ->
  serverUrl = $window.$CROSS.settings.serverURL
  clusterParams = "/os-aggregates/#{clusterId}"
  $http.put("#{serverUrl}#{clusterParams}", options)
    .success (data, status, headers) ->
      callback data
    .error (data, status, headers) ->
      toastr.error _("Falied update cluster!")

###
List server that contain info base instance and extended.
###
$cross.listDetailedServers = ($http, $window, $q, query, callback) ->
  serverURL = $window.$CROSS.settings.serverURL

  if query.dataFrom != undefined
    query.limit_from = query.dataFrom
    delete query.dataFrom
  if query.dataTo != undefined
    query.limit_to = query.dataTo
    delete query.dataTo
  if query.search == true
    instancesURL = "#{serverURL}/servers/search"
  else
    instancesURL = "#{serverURL}/servers"
  instances = $http.get(instancesURL, {
    params: query
  }).then(
    (response) ->
      return response.data
    (error) ->
      return {data: [], total: 0}
  )

  getAddr = (addresses) ->
    fixed = []
    floating = []
    fixedWeight = 0
    floatingWeight = 0
    for addrName, addrSet of addresses
      for addr in addrSet
        if addr['OS-EXT-IPS:type'] == 'fixed'
          fixed.push addr.addr
        else if addr['OS-EXT-IPS:type'] == 'floating'
          floating.push addr.addr

    if fixed.length > 0
      fixedArray = fixed[0].split('.')
      for i in fixedArray
        fixedWeight += parseInt(i)
    if floating.length > 0
      floatingArray = floating[0].split('.')
      for i in floatingArray
        floatingWeight += parseInt(i)

    return {
      fixed: fixed,
      floating: floating,
      fixedWeight: fixedWeight,
      floatingWeight: floatingWeight
    }

  # Ensure that multiple requests all return
  # TODO(ZhengYue): Error handler
  $q.all([instances])
    .then (values) ->
      serverList = []

      for instance in values[0].data
        server = new $cross.Server(instance, instanceAttrs)
        serverObj = server.getObject(server)
        delete serverObj.flavor
        address = JSON.parse(serverObj.addresses)
        addresses = getAddr address
        serverObj.fixed = addresses.fixed
        serverObj.floating = addresses.floating
        serverObj.fixedWeight = addresses.fixedWeight
        serverObj.floatingWeight = addresses.floatingWeight
        delete serverObj.addresses
        serverObj.vcpus = Number(serverObj.vcpus)
        serverObj.ram = Number(serverObj.ram)
        serverList.push serverObj

      callback serverList, values[0].total

###
Get a server.
###
$cross.serverGet = ($http, $window, $q, instanceId, callback) ->
  if !instanceId
    return
  serverUrl = $window.$CROSS.settings.serverURL
  server = $http.get("#{serverUrl}/servers/#{instanceId}")
    .then (response) ->
      return response.data
  volume = $http.get("#{serverUrl}/volumes?all_tenants=true")
    .then (response) ->
      return response.data
  image = $http.get("#{serverUrl}/images?all_tenants=true")
    .then (response) ->
      return response.data

  getAddr = (addresses) ->
    fixed = []
    floating = []
    for addrName, addrSet of addresses
      for addr in addrSet
        if addr['OS-EXT-IPS:type'] == 'fixed'
          fixed.push addr.addr
        else if addr['OS-EXT-IPS:type'] == 'floating'
          floating.push addr.addr

    return {fixed: fixed, floating: floating}

  $q.all([server, volume, image])
    .then (values) ->
      if values[0]
        server = new $cross.Server(values[0], instanceAttrs)
        volumes = server._apiresource.volumes if server._apiresource
        serverObj = server.getObject(server)
      if values[1] and values[2] and serverObj
        volume = values[1].data
        image = values[2].data
        for item in volume
          for serverVol of volumes
            if item.id == volumes[serverVol].id \
            and item.bootable == "true" \
            and item.volume_image_metadata
              metadata = JSON.parse item.volume_image_metadata
              imageId = metadata.image_id
        for item in image
          if item.id == imageId
            imageName = item.name

        if serverObj.addresses
          address = JSON.parse(serverObj.addresses)
          addresses = getAddr address
          serverObj.fixed = addresses.fixed
          serverObj.floating = addresses.floating
        else
          serverObj.fixed = ''
          serverObj.floating = ''
        if values[0].image_name
          serverObj.image_name = values[0].image_name
        else if imageName
          serverObj.image_name = imageName
        else
          serverObj.image_name = null
        if serverObj.image
          serverObj.image = JSON.parse(serverObj.image)
        if not serverObj.image
          serverObj.image = {}
          serverObj.image.id = imageId
        delete serverObj.addresses
        if values[0].volumes
          serverObj.volumes = values[0].volumes
        callback serverObj
      else
        callback null
    .catch (err) ->
      # FIXME(liuhaobo): Handle the error.
      console.error "Meet error: %s", err


$cross.serverDelete = ($http, $window, instanceId, force, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  requestData =
    url: "#{serverURL}/servers/#{instanceId}"
    method: 'DELETE'

  if force == 'force'
    requestData =
      url: "#{serverURL}/servers/#{instanceId}/action"
      method: 'POST'
      data: {"forceDelete": null}

  $http requestData
    .success (data, status, headers) ->
      callback status

$cross.serverLog = ($http, $window, instanceId, logLength, callback) ->
  if !instanceId
    return
  serverUrl = $window.$CROSS.settings.serverURL
  if logLength != 0
    params = {"os-getConsoleOutput": {"length": logLength}}
  else
    params = {"os-getConsoleOutput": {}}
  requestData =
    url: "#{serverUrl}/servers/#{instanceId}/action"
    method: 'POST'
    data: params

  $http requestData
    .success (data, status, headers) ->
      if data
        callback data.data
    .error (data, status, headers) ->
      msg = _("Log load error, try again later!")

$cross.serverConsole = ($http, $window, instanceId, callback) ->
  if !instanceId
    return
  serverUrl = $window.$CROSS.settings.serverURL
  requestData =
    url: "#{serverUrl}/servers/#{instanceId}/action"
    method: 'POST'
    data: {"os-getVNCConsole": {"type": "novnc"}}

  $http requestData
    .success (data, status, headers) ->
      if data
        callback data

action_dispatcher = (action, options) ->
  # TODO(ZhengYue): Full the action, current is sample set
  actionDataMap = {
    'reboot': {'reboot': {"type": "SOFT"}},
    'os-getVNCConsole':{'os-getVNCConsole': {"type": "novnc"}},
    'poweroff': {'os-stop': null},
    'poweron': {'os-start': null},
    'suspend': {'suspend': null},
    'wakeup': {'resume': null},
    'restore': {'restore': null},
    'resize': {'resize': {'flavorRef': options.flavorId}}
    'snapshot': {
      "createImage": {
        "name": options.name,
        "metadata": options.metadata || {}}}
    'addFloatingIp':
      "addFloatingIp":
        "address": options.address
        "fixed_ip": options.fixed_ip
    'removeFloatingIp':
      "removeFloatingIp":
        "address": options.address
    'avhosts': {'avhosts': {}}
    'live-migrate': {'live-migrate': options}
  }
  if options.addition and action == 'reboot'
    if !options.addition.default
      actionDataMap.reboot.reboot.type = 'HARD'
  return actionDataMap[action]

$cross.instanceAction = (action, $http, $window, options, callback) ->
  if !options.instanceId
    return
  serverUrl = $window.$CROSS.settings.serverURL
  $http.get "#{serverUrl}/servers/#{options.instanceId}"
    .success (server) ->
      options.metadata = server.metadata
      options.metadata = JSON.parse options.metadata
      requestData =
        url: "#{serverUrl}/servers/#{options.instanceId}/action"
        method: 'POST'
        data: action_dispatcher(action, options)

      $http requestData
        .success (data, status, headers) ->
          callback status, data
        .error (data, status, headers) ->
          callback status, data, headers
    .error (err, status, headers) ->
      callback status, err, headers

$cross.floatingipUpdate = (floatingIpId, $http, $window, params, callback) ->
  serverUrl = $window.$CROSS.settings.serverURL
  $http.put "#{serverUrl}/floatingips/#{floatingIpId}", params
    .success (floatingip, status) ->
      callback status, floatingip
    .error (err, status) ->
      callback status, err

$cross.nova =
  createFlavor: (opts, callback) ->
    $http = opts.$http
    $window = opts.$window
    serverUrl = $window.$CROSS.settings.serverURL
    params =
      params: opts.params
    $http.get "#{serverUrl}/os-flavors", params
      .success (flavors) ->
        if flavors.total == 0
          vcpus = opts.params['vcpus']
          ram = parseInt(opts.params['ram'] / 1024)
          disk = opts.params['disk']
          data = params.params
          data.name = "#{vcpus}U#{ram}G#{disk}G"
          $http.post "#{serverUrl}/os-flavors", data
            .success (flavor) ->
              callback undefined, flavor
            .error (err) ->
              callback err
              adder = "#{vcpus}vcpus, #{ram}GB, #{disk}GB"
              toastr.error _("Failed to create specified flavor with ") + adder
        else
          callback undefined, flavors.data[0]

# TODO: Extract this function into utils
getPoolLength = (pool) ->
  pat = /\d+.\d+.\d+.(\d+)/i
  matchRes = pat.exec(pool.start)
  if matchRes
    startPoint = parseInt(matchRes[1])
  else
    startPoint = 2
  endMatchRes = pat.exec(pool.end)
  if endMatchRes
    endPoint = parseInt(endMatchRes[1])
  else
    endPoint = 255
  return endPoint - startPoint

$cross.resourceStatis = ($http, $window, $q, callback) ->
  useNeutron = $window.$CROSS.settings.use_neutron
  serverUrl = $window.$CROSS.settings.serverURL
  hypervisorParams = "/os-hypervisors/statistics"
  networkParams = "/os-floating-ips-bulk"

  hypervisorStatis = $http.get("#{serverUrl}#{hypervisorParams}")
    .then (response) ->
      return response.data
  networkStatis = $http.get("#{serverUrl}#{networkParams}")
    .then (response) ->
      return response.data

  if not useNeutron
    $q.all([hypervisorStatis, networkStatis])
      .then (values) ->
        statistics = values[0]
        freeFloatingIps = 0
        for ip in values[1]
          if !ip.project_id
            freeFloatingIps += 1
        statistics.floating_total = values[1].length
        statistics.floating_free = freeFloatingIps
        callback statistics
  else
    networks = $http.get "#{serverUrl}/networks?router:external=true"
    subnets = $http.get "#{serverUrl}/subnets"
    floatings = $http.get "#{serverUrl}/floatingips"
    $q.all [networks, subnets, floatings, hypervisorStatis]
      .then (res) ->
        statistics = res[3]
        networkList = res[0].data
        subnetList = res[1].data
        floatingList = res[2].data
        pubSubs = []
        pubNets = {}
        floatingIpLength = 0
        for network in networkList
          pubNets[network.id] = network
        for subnet in subnetList
          if pubNets[subnet.network_id]
            pubSubs.push subnet

        if pubSubs.length > 0
          poolLength = 0
          for pubSub in pubSubs
            allocationPools = pubSub.allocation_pools
            for pool in allocationPools
              poolLength += getPoolLength(pool)
        else
          # NOTE: Set 253 as default length of floating ip pool
          poolLength = 253
        usedFloating = floatingList.length
        statistics.floating_total = poolLength
        statistics.floating_free = poolLength - usedFloating
        callback statistics

$cross.createCluster = ($http, $window, options, callback) ->
  serverURL = $window.$CROSS.settings.serverURL
  clusterParam = "#{serverURL}/os-aggregates"
  $http.post clusterParam, options
    .success (data, status, headers) ->
      callback null, data
    .error (data, status, headers) ->
      toastr.error _("Failed create cluster.")
      # NOTE: Set status as error mark
      callback status, data

$cross.deleteCluster = ($http, $window, clusterId, callback) ->
  if !clusterId
    return
  serverURL = $window.$CROSS.settings.serverURL
  clusterParam = "#{serverURL}/os-aggregates/#{clusterId}"
  $http.delete clusterParam
    .success (data, status, headers) ->
      callback data
    .error (data, status, headers) ->
      callback data

$cross.updateClusterNodes = ($http, $window, options, callback) ->
  if !options.clusterId
    return
  serverURL = $window.$CROSS.settings.serverURL
  clusterParams = "#{serverURL}/os-aggregates/#{options.clusterId}/action"
  params = options.params
  $http.post clusterParams, params
    .success (data, status, headers) ->
      callback data
    .error (data, status, headers) ->
      toastr.error _("Failed update cluster!")
