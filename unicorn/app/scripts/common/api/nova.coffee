'use stricy'

instanceAttrs = ['id', 'name', 'status', 'OS-EXT-SRV-ATTR:hypervisor_hostname'
                 'flavor', 'tenant_id', 'user_id', 'addresses',
                 'project_name', 'user_name', 'vcpus', 'ram', 'disk',
                 'OS-EXT-STS:task_state', 'created', 'image',
                 'image_name', 'volumes', 'metadata', 'serverTime']

serverURL = window.$UNICORN.settings.serverURL

###
Simple wrapper around nova server API
###
class $unicorn.Server extends $unicorn.APIResourceWrapper
  constructor: (instance, attrs) ->
    super instance, attrs

###
Simple wrapper around nova flavor API
###
class $unicorn.Flavor extends $unicorn.APIResourceWrapper
  constructor: (flavor, attrs) ->
    super flavor, attrs

###
List server that contain base instance info.
###
$unicorn.listServers = ($http, $window, callback) ->
  requestData =
    url: "#{serverURL}/servers"
    method: 'GET'

  $http requestData
    .success (instances, status, headers) ->
      serverList = []
      for instance in instances.data
        server = new $unicorn.Server(instance, instanceAttrs)
        serverList.push server.getObject(server)
      callback serverList

$unicorn.listHosts = ($http, $window, $q, callback) ->
  hypervisorsParams = "/os-hypervisors/detail"
  servicesParams = "/os-services?binary=nova-compute"
  hypervisors = $http.get("#{serverURL}#{hypervisorsParams}")
    .then (response) ->
      return response.data
  services = $http.get("#{serverURL}#{servicesParams}")
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

$unicorn.getHost = ($http, $window, hostId, callback) ->
  hypervisorsParams = "/os-hypervisors/#{hostId}"
  $http.get "#{serverURL}#{hypervisorsParams}"
    .success (data, status, headers) ->
      callback data
    .error (data, status, headers) ->
      toastr.error(_("Failed get compute node info!"))

$unicorn.getAvailableHosts = ($http, $window, $q, callback) ->
  clustersParams = "/os-clusters"
  clusters = $http.get("#{serverURL}#{clustersParams}")
    .then (response) ->
      return response.data
  hypervisorsParams = "/os-hypervisors"
  hypervisors = $http.get("#{serverURL}#{hypervisorsParams}")
    .then (response) ->
      return response.data

  clusteredList = []
  availableList = []
  $q.all([clusters, hypervisors])
    .then (values) ->
      clusterList = values[0]
      computeNodes = values[1]
      for cluster in clusterList
        for node in cluster.compute_nodes
          clusteredList.push node.id

      for host in computeNodes
        isUsed = false
        if host.id in clusteredList
          isUsed = true
        if isUsed == false
          availHost =
            {
              id: host.id
              name: host.hypervisor_hostname
            }
          availableList.push availHost

      callback availableList

###
List server that contain info base instance and extended.
###
$unicorn.listDetailedServers = ($http, $window, $q, query, callback) ->
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
      toastr.error _("Error at list instances, try again later!")
      return {data: [], total: 0}
  )

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

  getLeftTime = (created_at, time_long_sec, server_time) ->
    # params:
    #   created_at: the ISOString of instance created
    #   time_long_sec: the due time of instance by seconds

    # The current UTC time by millsecdes
    currentSecs = server_time or (new Date()).getTime()
    # Convert the created_at to millsec
    createdAtSecs = (new Date(created_at)).getTime()

    passedTimeSec = currentSecs - createdAtSecs
    if time_long_sec
      leftTime = time_long_sec - (passedTimeSec / 1000)
      if leftTime > 0
        return leftTime
      else
        return 0

  $q.all([instances])
    .then (values) ->
      serverList = []

      for instance in values[0].data
        server = new $unicorn.Server(instance, instanceAttrs)
        serverObj = server.getObject(server)
        delete serverObj.flavor
        address = JSON.parse(serverObj.addresses)
        addresses = getAddr address
        serverObj.fixed = addresses.fixed
        serverObj.floating = addresses.floating
        if serverObj.metadata
          metadata = JSON.parse(serverObj.metadata)
          due_time = metadata.due_time_info
          if not due_time
            due_time = metadata['WORKFLOW:due_time']
          else
            due_time = JSON.parse(due_time).due_time
          if due_time
            serverObj.remaining = getLeftTime(serverObj.created, due_time, serverObj.serverTime)
          else
            serverObj.remaining = null
        else
          serverObj.ramaining = null
        delete serverObj.addresses
        serverList.push serverObj

      callback serverList, values[0].total

###
Get a server.
###
$unicorn.serverGet = ($http, $q, instanceId, callback) ->
  if !instanceId
    return
  server = $http.get("#{serverURL}/servers/#{instanceId}")
    .then (response) ->
      return response.data
  volume = $http.get("#{serverURL}/volumes?all_tenants=true")
    .then (response) ->
      return response.data
  image = $http.get("#{serverURL}/images?all_tenants=true")
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

  getLeftTime = (created_at, time_long_sec, server_time) ->
    # params:
    #   created_at: the ISOString of instance created
    #   time_long_sec: the due time of instance by seconds

    # The current UTC time by millsecdes
    currentSecs = server_time or (new Date()).getTime()
    # Convert the created_at to millsec
    createdAtSecs = (new Date(created_at)).getTime()

    passedTimeSec = currentSecs - createdAtSecs
    if time_long_sec
      leftTime = time_long_sec - (passedTimeSec / 1000)
      if leftTime > 0
        return leftTime
      else
        return null

  $q.all([server, volume, image])
    .then (values) ->
      if values[0]
        server = new $unicorn.Server(values[0], instanceAttrs)
        serverObj = server.getObject(server)
      if values[1] and values[2]
        volume = values[1].data
        image = values[2].data
        for item in volume
          for serverVol in server._apiresource.volumes
            if item.id == serverVol.id and item.bootable == "true"
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
        delete serverObj.addresses
        if serverObj.metadata
          metadata = JSON.parse(serverObj.metadata)
          due_time = metadata.due_time_info
          if not due_time
            due_time = metadata['WORKFLOW:due_time']
          else
            due_time = JSON.parse(due_time).due_time
          if due_time
            serverObj.remaining = getLeftTime(serverObj.created, due_time, serverObj.serverTime)
          else
            serverObj.remaining = null
        else
          serverObj.ramaining = null

        if values[0].volumes
          serverObj.volumes = values[0].volumes
        callback serverObj
      else
        callback null

$unicorn.serverDelete = ($http, $window, instanceId, force, callback) ->
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

$unicorn.serverLog = ($http, $window, instanceId, logLength, callback) ->
  if !instanceId
    return
  if logLength != 0
    params = {"os-getConsoleOutput": {"length": logLength}}
  else
    params = {"os-getConsoleOutput": {}}
  requestData =
    url: "#{serverURL}/servers/#{instanceId}/action"
    method: 'POST'
    data: params

  $http requestData
    .success (data, status, headers) ->
      if data
        callback data.data
    .error (data, status, headers) ->
      msg = _("Log load error, try again later!")

$unicorn.serverConsole = ($http, $window, instanceId, callback) ->
  if !instanceId
    return
  requestData =
    url: "#{serverURL}/servers/#{instanceId}/action"
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
    if options.addition.default
      actionDataMap.reboot.reboot.type = 'HARD'
  return actionDataMap[action]

$unicorn.instanceAction = (action, $http, $window, options, callback) ->
  if !options.instanceId
    return
  requestData =
    url: "#{serverURL}/servers/#{options.instanceId}/action"
    method: 'POST'
    data: action_dispatcher(action, options)

  $http requestData
    .success (data, status, headers) ->
      callback status, data, headers
    .error (err, status, headers) ->
      callback status, err, headers

$unicorn.nova =
  createFlavor: (opts, callback) ->
    $http = opts.$http
    $window = opts.$window
    params =
      params: opts.params
    $http.get "#{serverURL}/os-flavors", params
      .success (flavors) ->
        if flavors.total == 0
          vcpus = opts.params['vcpus']
          ram = parseInt(opts.params['ram'] / 1024)
          disk = opts.params['disk']
          data = params.params
          data.name = "#{vcpus}U#{ram}G#{disk}G"
          $http.post "#{serverURL}/os-flavors", data
            .success (flavor) ->
              callback undefined, flavor
            .error (err) ->
              callback err
              adder = "#{vcpus}vcpus, #{ram}GB, #{disk}GB"
              toastr.error _("Failed to create specified flavor with ") + adder
        else
          callback undefined, flavors.data[0]
