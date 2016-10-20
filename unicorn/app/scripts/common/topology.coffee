# define topology module

$unicorn.topology =
  DIS_LARGER: 200
  DIS_SMALL: 140
  ELE_WIDTH: 72
  ELE_WIDTH_SMALL: 36
  ELE_HEIGHT: 64
  ELE_HEIGHT_SMALL: 32
  LINE_WIDTH: 2
  LINE_WIDTH_SMALL: 1
  BACK_LIST: ["#fece72", "#a9e4df", "#cabef1", "#d6edbb", "#f1c5e7"]
  _get_back_: (index) ->
    back = $unicorn.topology.BACK_LIST
    return back[index % back.length]

  _draw_subnet_: (sub, index) ->
    $sub = angular.element("<div></div>")
    $sub.addClass("topology-network-subnet")
    color = $unicorn.topology._get_back_(index - 1)
    $sub.css "background-color", color
    $sub.attr "background-color", color
    $sub.attr("id", "__subnet_#{sub.id}")
    $sub_back = angular.element "<div class='subnet-back'></div>"
    $sub_back.html "<div class='topology-port-title'>#{sub.cidr}</div>"
    return $sub.append $sub_back

  _draw_net_: (net, $subs, z_index) ->
    color = $unicorn.topology._get_back_(z_index - 1)
    $net = angular.element "<div></div>"
    $title = angular.element "<div></div>"
    $backgroud = angular.element "<div class='topology-network-back'></div>"
    $backgroud.css "background-color", color
    $backgroud.appendTo $net
    $title.addClass "topology-network-title"
    $title.html net.name
    $title.appendTo $net
    $net.addClass("topology-network")
    $net.attr("id", "__net_#{net.id}")
    $net.attr("background-color", color)
    $net.css {
      marginTop: $unicorn.topology.DIS_LARGER
      marginButtom: $unicorn.topology.DIS_LARGER
      zIndex: z_index
    }
    $net.append $subs

  _set_net_pos_: (nets, subnets, routers, ports) ->
    orders = []
    for port in ports
      if port.device_owner == 'network:router_interface' or port.device_owner == 'network:router_interface_distributed'
        device_id = port.device_id
        if not routers["router_#{device_id}"]
          continue
        else if not routers["router_#{device_id}"].interfaces
          routers["router_#{device_id}"].interfaces = []
        fixed_ips = port.fixed_ips
        for fixed in fixed_ips
          sub = subnets["sub_#{fixed.subnet_id}"]
          if not sub
            continue
          routers["router_#{device_id}"].interfaces.push "net_#{sub.network_id}"
    maps = {}
    for r of routers
      router = routers[r]
      info = router.external_gateway_info
      if not info
        continue
      net_id = info.network_id
      if not maps["dev_#{net_id}"]
        maps["dev_#{net_id}"] = []
      maps["dev_#{net_id}"].concat(router.interfaces or [])
    for net_id of nets
      insert = 0
      net = nets[net_id]
      interfaces = maps["dev_#{net.id}"] or []
      for order in orders
        if order in interfaces
          break
        if not nets[order]['router:external']
          break
        insert += 1

      orders.splice insert, 0, net_id
    return orders

  _drawNetTopology: (nets, orders, $ele, options) ->
    z_index = 0
    for net_id in orders
      $subs = []
      net = nets[net_id]
      if net['tenant_id'] != $UNICORN.person.project.id
        if not net['router:external'] and not net['shared']\
        and $UNICORN.person.user.name != "admin"
          continue
      for sub_id of net.subnets
        sub = net.subnets[sub_id]
        if not Object.keys(sub).length
          continue
        $sub = $unicorn.topology._draw_subnet_(sub, z_index + 1)
        $subs.push $sub
      $ele.append $unicorn.topology._draw_net_(net, $subs, z_index + 1)
      z_index += 1

  _draw_router_detail_: (router, $ele) ->
    $detail = angular.element "<div class='topology-detail-cont'></div>"
    $wrap = angular.element "<div class='topology-detail-wrap'></div>"
    $wrap.html("<div class='wrap-outer'></div><div class='wrap-inner'></div>")
    $detail.attr "id", "__router_#{router.id}_detail"
    gateway = router.external_gateway_info
    if not gateway
      html = "<div class='item-name'><span class='item-title'>#{_('Name')}</span>:&nbsp;" +
             "<span class='item-value'>#{router.name}</div></div>" +
             "<div class='item-status'><span class='item-title'>#{_('Status')}</span>:&nbsp;" +
             "<span class='item-value'><i class='status-#{router.status}'></i></span></div>"
      $detail.append($wrap).append(html).appendTo $ele
      return
    fixed_ips = gateway.external_fixed_ips
    gate = ""
    for fixed in fixed_ips
      gate += "#{fixed.ip_address}&nbsp;"
    html = "<div class='item-name'><span class='item-title'>#{_('Name')}</span>:&nbsp;" +
           "<span class='item-value'>#{router.name}</div></div>" +
           "<div class='item-status'><span class='item-title'>#{_('Status')}</span>:&nbsp;" +
           "<span class='item-value'><i class='status-#{router.status}'></i></span></div>" +
           "<div class='item-gateway'><span class='item-title'>#{_('Gateway')}</span>:&nbsp;" +
           "<span class='item-value'>#{gate}</span></div>"
    $detail.append($wrap).append(html).appendTo $ele

  _draw_router_: (router) ->
    $router = angular.element "<div></div>"
    $router.addClass "topology-router"
    $router.attr "id", "__router_#{router.id}"
    dis = $unicorn.topology.DIS_LARGER + $unicorn.topology.ELE_WIDTH
    $router.css {
      width: $unicorn.topology.ELE_WIDTH
      height: $unicorn.topology.ELE_HEIGHT
      bottom: - dis / 2
    }
    $router.html "<div class='topology-router-title' title='#{router.name}'>#{router.name}</div>"
    $unicorn.topology._draw_router_detail_ router, $router
    return $router

  _draw_port_: (port, ip_address) ->
    $port = angular.element "<div></div>"
    $port.addClass "topology-port"
    $port.attr "id", "__port_#{port.id}"
    $port.css 'width', $unicorn.topology.LINE_WIDTH
    $ip = angular.element "<div class='topology-port-title'>#{ip_address}</div>"
    $ip.appendTo $port
    $tagTop = angular.element "<div class='topology-port-top'></div>"
    $tagBut = angular.element "<div class='topology-port-buttom'></div>"
    $tagBut.addClass("topology-port-link").appendTo $port
    $tagTop.addClass("topology-port-link").appendTo $port
    return $port

  _draw_server_detail_: (server, $ele) ->
    $detail = angular.element "<div class='topology-detail-cont'></div>"
    $wrap = angular.element "<div class='topology-detail-wrap'></div>"
    $wrap.html("<div class='wrap-outer'></div><div class='wrap-inner'></div>")
    $detail.attr "id", "__server_#{server.id}_detail"
    html = "<div class='item-name'><span class='item-title'>#{_('Name')}</span>" +
           "<span class='item-value'>:&nbsp;#{server.name}</div></div>" +
           "<div class='item-status'><span class='item-title'>#{_('Status')}</span>" +
           "<span class='item-value'>:&nbsp;<i class='status-#{server.status}'></i></span></div>" +
           "<div class='item-ram'><span class='item-title'>#{_('Ram')}</span>" +
           "<span class='item-value'>:&nbsp;#{server.ram}M</span></div>" +
           "<div class='item-cpu'><span class='item-title'>#{_('vCPU')}</span>" +
           "<span class='item-value'>:&nbsp;#{server.vcpus}</span></div>"
    $detail.append($wrap).append(html).appendTo $ele

  _draw_server_: (server) ->
    $server = angular.element "<div></div>"
    $server.attr "id", "__server_#{server.id}"
    $server.addClass "topology-server"
    dis = $unicorn.topology.DIS_LARGER + $unicorn.topology.ELE_WIDTH
    $server.css {
      width: $unicorn.topology.ELE_WIDTH
      height: $unicorn.topology.ELE_HEIGHT
      bottom: - dis / 2
    }
    $server.html "<div class='topology-server-title' title='#{server.name}'>#{server.name}</div>"
    $unicorn.topology._draw_server_detail_ server, $server
    return $server

  _set_position_: ($join, $ele, ele) ->
    $nets = $ele.find ".topology-network"
    width = $ele.width()
    offset = $ele.offset()
    start = 0
    ele_width = $unicorn.topology.ELE_WIDTH
    dis = $unicorn.topology.DIS_LARGER / 4 + ele_width
    if ele and width / ele > dis
      start = (width - ele * dis) / 2
    else if ele and width / ele < dis
      $ele.css "width", dis * ele
    $nets.each (index, e) ->
      $net = angular.element e
      $routers = $net.find ".topology-router"
      $servers = $net.find ".topology-server"
      len = $routers.length + $servers.length
      $routers.each (index, router) ->
        $router = angular.element router
        $router.css 'left', start
        start += dis
      $servers.each (index, server) ->
        $server = angular.element server
        $server.css 'left', start
        start += dis
    line_width = $unicorn.topology.LINE_WIDTH
    for join in $join
      from = join.attr "connect-from"
      to = join.attr "connect-to"
      $from = angular.element "##{from}"
      $to = angular.element "##{to}"
      from_offset = $from.offset()
      to_offset = $to.offset()
      from_top = from_offset.top - offset.top
      to_top = to_offset.top - offset.top
      left = Math.max to_offset.left, from_offset.left
      cont_width = Math.min($from.width(), $to.width()) + 2
      dis = cont_width - line_width
      left = left - offset.left + dis / 2
      height_cur = to_top - from_top
      if to_top > from_top
        height_cur -= $from.height()
        from_top += $from.height()
      else
        height_cur = from_top - to_top
        from_top = to_top + $to.height()
        height_cur -= to_top
      interfaces = parseInt($from.attr("router-interfaces") or 0)
      index = parseInt($from.attr("router-interface-index") or 0)
      color = $to.attr('background-color')
      if interfaces
        distance = cont_width / interfaces
        left = left - cont_width / 2 + index * distance + distance / 2
        $from.attr("router-interface-index", index + 1)
      else
        color = $from.attr('background-color')
      inters = parseInt($to.attr("server-interfaces") or 0)
      inx = parseInt($to.attr("server-interface-index") or 0)
      if inters
        color = $from.attr('background-color')
        distance = cont_width / inters
        left = left - cont_width / 2 + inx * distance + distance / 2
        $to.attr("server-interface-index", inx + 1)
      join.css {
        left: left
        top: from_top
        height: height_cur
        backgroundColor: color
      }
      join.find(".topology-port-link").css "background-color", color

  _draw_join_: (ports, routers, servers, subnets, $ele) ->
    $join = []
    rts = []
    rt = {}
    ele = 0
    $nets = $ele.find('.topology-network')
    for port in ports
      if port.device_owner == 'network:router_interface' or port.device_owner == 'network:router_interface_distributed'
        fixed_ips = port.fixed_ips
        router_id = port.device_id
        if rt["router_#{router_id}"]
          rs = rt["router_#{router_id}"]
        else if router_id not in rts
          rs = $unicorn.topology._draw_router_(routers["router_#{router_id}"])
        else
          rs = angular.element "#__router_#{router_id}"
        interfaces = parseInt(rs.attr("router-interfaces") or 0)
        interfaces = parseInt(rs['router-interfaces'] or interfaces)
        for fixed in fixed_ips
          $port = $unicorn.topology._draw_port_ port, fixed.ip_address
          $port.attr "connect-from", "__router_#{router_id}"
          $port.attr "connect-to", "__subnet_#{fixed.subnet_id}"
          interfaces += 1
          $join.push $port
        rs.attr "router-interfaces", interfaces
        rs['router-interfaces'] = interfaces
        rt["router_#{router_id}"] = rs
      else if port.device_owner == 'network:router_gateway'
        fixed_ips = port.fixed_ips
        router_id = port.device_id
        ele += 1
        for fixed in fixed_ips
          subnet_id = fixed.subnet_id
          network_id = subnets["sub_#{subnet_id}"].network_id
          $network = angular.element "#__net_#{network_id}"
          if rt["router_#{router_id}"]
            rs = rt["router_#{router_id}"]
            rts.push router_id
          else if router_id not in rts
            rts.push router_id
            rs = $unicorn.topology._draw_router_(routers["router_#{router_id}"])
          rs.css 'z-index', $network.css('z-index')
          rs.css 'border-color', $network.attr('background-color')
          rs.attr 'background-color', $network.attr('background-color')
          rs.appendTo $network
          $port = $unicorn.topology._draw_port_ port, fixed.ip_address
          $port.attr "connect-to", "__router_#{router_id}"
          $port.attr "connect-from", "__subnet_#{fixed.subnet_id}"
          $join.push $port
      else if port.device_owner.indexOf('compute:') == 0
        instance_id = port.device_id
        $server = angular.element "#__server_#{instance_id}"
        parent = null
        if not $server.length and servers["instance_#{instance_id}"]
          $server = $unicorn.topology._draw_server_ servers["instance_#{instance_id}"]
        else
          parent = $server.parent()
        fixed_ips = port.fixed_ips
        ele += 1
        for fixed in fixed_ips
          if servers["instance_#{instance_id}"]
            subnet = fixed.subnet_id
            $port = $unicorn.topology._draw_port_ port, fixed.ip_address
            network_id = subnets["sub_#{subnet}"].network_id
            $network = angular.element "#__net_#{network_id}"
            if parent != null
              interfaces = parseInt($server.attr("server-interfaces") or 1)
              if $nets.index($network) > $nets.index(parent)
                $server.appendTo $network
              $server.attr('server-interfaces', interfaces + 1)
            else
              $server.appendTo $network
            $server.attr 'background-color', $network.attr('background-color')
            $port.attr "connect-to", "__server_#{instance_id}"
            $port.attr "connect-from", "__subnet_#{subnet}"
            $join.push $port

    for rout of routers
      router_id = rout.substring(7)
      if router_id in rts
        continue
      router = routers[rout]
      if not rt[rout]
        $router = $unicorn.topology._draw_router_(routers[rout])
      else
        $router = rt[rout]
      ele += 1
      gateway_info = router.external_gateway_info
      if not gateway_info
        nts = $ele.find('.topology-network')
        if nts.length
          $router.appendTo nts.eq(0)
          continue
        $router.appendTo $ele
        continue
      net_id = gateway_info.network_id
      fixed_ips = gateway_info.external_fixed_ips
      $network = angular.element "#__net_#{net_id}"
      $router.appendTo $network
      for fixed in fixed_ips
        port =
          id: "router-exteral-gateway-#{router_id}"
        $port = $unicorn.topology._draw_port_ port, fixed.ip_address
        $port.attr "connect-to", "__router_#{router_id}"
        $port.attr "connect-from", "__net_#{net_id}"
        $join.push $port

    $ele.append $join
    $unicorn.topology._set_position_ $join, $ele, ele

  _set_root_top_: ($ele, drawLine) ->
    width = $ele.width()
    $root = angular.element "<div></div>"
    $root.addClass "topology-root"
    $root.appendTo $ele
    large = $unicorn.topology.DIS_LARGER
    $root.css {
      top: - large * 5 / 6
      left: (width - $root.width()) / 2
    }
    if not drawLine
      return
    $port = angular.element "<div></div>"
    $port.addClass "topology-port"
    $port.attr "id", "__port_root"
    $port.css 'width', $unicorn.topology.LINE_WIDTH
    $tagTop = angular.element "<div class='topology-port-top'></div>"
    $tagBut = angular.element "<div class='topology-port-buttom'></div>"
    $tagBut.addClass("topology-port-link").appendTo $port
    $tagTop.addClass("topology-port-link").appendTo $port
    left = (width - $unicorn.topology.LINE_WIDTH) / 2
    color = $unicorn.topology._get_back_(0)
    $port.css {
      left: left
      top: - large * 5 / 6 + $root.height() - 2
      height: large / 3 + 2
      backgroundColor: color
    }
    $port.appendTo $ele
    $tagTop.css "background-color", color
    $tagBut.css "background-color", color

  drawNetView: (netView, $ele, options) ->
    shared = netView.shared or []
    nets = netView.networks or {}
    subnets = netView.subnets or {}
    routers = netView.routers or {}
    ports = netView.ports or []
    servers = netView.servers or {}
    orders = $unicorn.topology._set_net_pos_(nets, subnets, routers, ports)
    $unicorn.topology._set_root_top_($ele, orders.length)
    $unicorn.topology._drawNetTopology(nets, orders, $ele, options)
    $unicorn.topology._draw_join_(ports, routers, servers, subnets, $ele)

  # Host topology view.
  # node box size.
  _NODE_:
    width: 70
    height: 52
    root:
      width: 72
      height: 52
  _OFFSET_:
    left: (72 - 70) / 2
  # node distance between.
  _DISTANCE_:
    X: 30
    Y: 40
  # node type.
  _NODE_TYPE_:
    host: 'host'
    vm: 'vm'
    cluster: 'cluster'
    root: 'root'
  # max nodes for same generation.
  _MAX_SAME_GENERATION_NODES_: 15
  # nodes with those type show join.
  _JOIN_NODE_TYPE_: ['host', 'cluster']

  ###*
  # Add node tip
  #
  ###
  _addNodeTip: (options, target) ->
    if angular.element("##{options.id}").length
      tip = angular.element("##{options.id}")
    else
      tip = angular.element("<div></div>")
      tip.addClass "cross-topology-node-tip"
      tip.attr({
        id: options.id
        nodeId: options.nodeId
      }).appendTo target
    tip.css({
      left: options.left - 25
      top: options.top + 15
    }).html(options.number).fadeIn()

  ###*
  # Add line join
  #
  ###
  _addLineJoin: (options, target) ->
    if angular.element("##{options.id}").length
      join = angular.element("##{options.id}")
    else
      join = angular.element("<div></div>")
      join.addClass "cross-topology-line-join"
      join.attr({
        id: options.id
        nodeId: options.nodeId
      }).appendTo target
    join.css({
      left: options.left - $unicorn.topology._NODE_.width * 1 / 5
      top: options.top - $unicorn.topology._NODE_.height * 3 / 5
      width: $unicorn.topology._NODE_.width * 2 / 5
      height: $unicorn.topology._NODE_.height * 3 / 5
    })
    if options.expend then join.fadeOut() else join.fadeIn()

  evenNum: (num) ->
    if num % 2 == 0
      return num - 1
    return num

  ###*
  # Draw link.
  #
  ###
  _drawLink: (root, hostView, target, options) ->
    children = hostView[root].children
    if not children or not children.length
      return

    XMLNS = 'xmlns="http://www.w3.org/2000/svg"'
    VERSION = 'version="1.1"'
    STROKE_WIDTH = 2
    index = 0
    curr_x = 0
    pre_x = 0
    len = hostView[root].children.length

    # caculate width, height, initial line path.
    firstChildID = hostView[hostView[root].children[0]].id
    lastChildID = hostView[hostView[root].children[len - 1]].id
    $firstChildID = "#cross_topology_node_id_#{firstChildID}"
    $lastChildID = "#cross_topology_node_id_#{lastChildID}"
    firstChild = angular.element("#{$firstChildID}")
    lastChild = angular.element("#{$lastChildID}")
    width = parseInt(lastChild.attr("left"))
    width -= parseInt(firstChild.attr("left"))
    width += STROKE_WIDTH
    height = $unicorn.topology._DISTANCE_.Y
    width = $unicorn.topology.evenNum width
    height = $unicorn.topology.evenNum height
    d = "M#{width/2} 0 L#{width/2} #{height/2}"
    path = "<path d='#{d}' />"
    d = "M0 #{height/2} L#{width} #{height/2}"
    path += "<path d='#{d}' />"
    for child in children
      childID = "cross_topology_node_id_#{hostView[child].id}"
      curr_x = parseInt(angular.element("##{childID}").attr("left"))
      if index == 0
        pre_x = curr_x
      curr_x += .5
      d = "M#{curr_x-pre_x} #{height/2} L#{curr_x-pre_x} #{height}"
      path += "<path d='#{d}' />"
      index += 1
    lineId = "cross_topology_line_id_#{hostView[root].id}"

    # Remove svg dom as it does not support jquery.html(path)
    if angular.element("##{lineId}").length
      angular.element("##{lineId}").remove()

    liner_str = "<svg class='cross-topology-line' #{XMLNS} #{VERSION}>"
    liner_str += path + '</svg>'
    liner = angular.element(liner_str)
    liner.attr({id: lineId}).appendTo target

    left = parseInt(firstChild.attr("left"))
    left += $unicorn.topology._NODE_.width / 2
    top = parseInt(firstChild.attr("top"))
    top -= $unicorn.topology._DISTANCE_.Y
    if root == $unicorn.topology._NODE_TYPE_.root
      top += $unicorn.topology._NODE_.root.height
      top -= $unicorn.topology._NODE_.height
    liner.attr({left: left, top: top})
      .css({
        width: width
        height: height
        position: 'absolute'
        left: left
        top: top
      }).slideDown()

  ###*
  #Set node position
  #
  ###
  _setPosition: (root, hostView, target, options) ->
    className = "cross-topology-node"
    nodeId = "cross_topology_node_id_#{hostView[root].id}"
    if not angular.element("##{nodeId}").length
      node = angular.element("<div></div>")
      node.addClass(className)
      if hostView[root].name
        name = hostView[root].name.split(".")[0]
        if name.length > 15
          name = "#{name.substr(0,12)}..."
        node.html "<div class='content'>#{name}</div>"
      node.attr({
        id: "#{nodeId}"
        nodeId: hostView[root].id
        title: hostView[root].name
      }).appendTo target
    else
      node = angular.element("##{nodeId}")
    width = $unicorn.topology._NODE_.width
    height = $unicorn.topology._NODE_.height
    distanceX = $unicorn.topology._DISTANCE_.X
    distanceY = $unicorn.topology._DISTANCE_.Y
    node.addClass("cross-topology-#{hostView[root].type}")
        .addClass("cross-topology-element")
        .addClass("animated rollIn")
    top = (hostView[root].depth - 1) * (height + distanceY)
    children = hostView[root].children
    notShowChildren = hostView[root].not_show_children
    joinNodeType = $unicorn.topology._JOIN_NODE_TYPE_
    runningVms = hostView[root].running_vms
    if not children || (not children.length && not runningVms) || notShowChildren
      left = (options.left - 1) * (width + distanceX)
      left += $unicorn.topology._OFFSET_.left
      if children && hostView[root].type in joinNodeType
        options =
          top: top
          left: left + $unicorn.topology._NODE_.width
          id: "cross_topology_node_tip_id_#{hostView[root].id}"
          nodeId: hostView[root].id
          number: hostView[root].running_vms || children.length
        $unicorn.topology._addNodeTip options, target
    else if children.length
      len = hostView[root].children.length
      firstChildID = hostView[hostView[root].children[0]].id
      lastChildID = hostView[hostView[root].children[len - 1]].id
      firstNodeID = "cross_topology_node_id_#{firstChildID}"
      lastNodeID = "cross_topology_node_id_#{lastChildID}"
      firstChild = angular.element("##{firstNodeID}")
      lastChild = angular.element("##{lastNodeID}")
      left = parseInt(lastChild.attr("left"))
      left = (left + parseInt(firstChild.attr("left"))) / 2
    if hostView[root].type in joinNodeType && children
      if children.length || hostView[root].running_vms
        options =
          left: left + $unicorn.topology._NODE_.width / 2
          top: top + $unicorn.topology._NODE_.height
          id: "cross_topology_line_join_id_#{hostView[root].id}"
          nodeId: hostView[root].id
          expend: hostView[root].not_show_children
        $unicorn.topology._addLineJoin options, target

    if hostView[root].type == 'vm'
      status = hostView[root].status.toLowerCase()
      noticeStatus = ['error', 'pause']
      if $UNICORN.settings.VM_NOTICE_STATUS
        noticeStatus = $UNICORN.settings.VM_NOTICE_STATUS
      if status in noticeStatus
        $("<div class='error #{status}'></div>").appendTo node

    if hostView[root].type == $unicorn.topology._NODE_TYPE_.root
      height = $unicorn.topology._NODE_.root.height
      width = $unicorn.topology._NODE_.root.width
      left -= (width - $unicorn.topology._NODE_.width) / 2
      top -= height - $unicorn.topology._NODE_.height
    top += height - $unicorn.topology._NODE_.height
    node.css({width: width, height: height})
      .attr({left: left, top: top, display: "block"})

  ###*
  # Set _index as 0
  #
  ###
  _clearIndex: (hostView) ->
    for key of hostView
      hostView[key]._index = 0
    hostView

  ###*
  # Clear Descendant.
  #
  ###
  _hideDescendant: (root, hostView) ->
    if not hostView[root].children
      return
    line = angular.element("#cross_topology_line_id_#{root}")
    line.fadeOut()
    joinId = "cross_topology_line_join_id_#{hostView[root].id}"
    angular.element("##{joinId}").hide()
    tipId = "cross_topology_node_tip_id_#{hostView[root].id}"
    angular.element("##{tipId}").hide()
    for child in hostView[root].children
      childId = "cross_topology_node_id_#{hostView[child].id}"
      childNode = angular.element("##{childId}")
      childNode.fadeOut().attr("display", "none")
      $unicorn.topology._hideDescendant child, hostView

  ###*
  #
  #
  ###
  _handleHide: (root, hostView) ->
    children = hostView[root].children
    if not children or not children.length
      return hostView
    for child in children
      if hostView[child].not_show_children == undefined
        hostView[child].not_show_children = true
    return hostView

  ###*
  # Here, I use postorder traversal to draw host topology.
  # First, set node position and draw link line.
  # Algorithm as:
  #   1 Loop:
  #   2 If root node has not parent, set depth 1
  #     else depth +1.
  #   3 If show node children or node is leaf, set node position.
  #     Set leaf counter +1, pop node and continue
  #   4 If not node _index, set children node index 0.
  #   5 If _index < node children length, set _index +1 and
  #     push node . Otherwise, set node position, draw link
  #     line and pop node as current node.
  # Second, show node from root to leaves.
  # Third, set container size.
  # Last, set node action(hide or display children nodes).
  #
  # @params hostView: {object}, node list.
  #   Options of hostView item:
  #     `id`: Unique node id.
  #     `name`: Node name.
  #     `parent`: Optional, parent id.
  #     `type`: Node type(root, cluster, host, vm).
  #     `children`: Optional, children id list.
  #     `not_show_children`: Optional, wether not show children node.
  #     `running_vms`: Optional, optional key only for host node.
  #
  # @params target: {jQuery object}, host topology container.
  # @params options: {object}, self define options.
  ###
  _drawTopology: (hostView, target, options) ->
    root = "root"
    options = options || {}
    copyView = []
    options.left = 0
    maxDepth = 1
    loop
      if not hostView[root]
        break if copyView.length == 0
        root = copyView.pop()
        continue
      if not hostView[root].parent
        hostView[root].depth = 1
      else
        if hostView[hostView[root].parent].depth > maxDepth
          maxDepth = hostView[hostView[root].parent].depth
        hostView[root].depth = hostView[hostView[root].parent].depth + 1
      notShowChildren = hostView[root].not_show_children
      children = hostView[root].children
      if not children || not children.length || notShowChildren
        options.left += 1
        $unicorn.topology._setPosition root, hostView, target, options
        break if copyView.length == 0
        root = copyView.pop()
        continue
      if hostView[root]._index == undefined
        hostView[root]._index = 0
      if hostView[root]._index < hostView[root].children.length
        queue_index = hostView[root]._index
        copyView.push(root)
        hostView[root]._index += 1
        root = hostView[root].children[queue_index]
      else
        $unicorn.topology._setPosition root, hostView, target, options
        $unicorn.topology._drawLink root, hostView, target, options
        break if copyView.length == 0
        root = copyView.pop()

    containerH = maxDepth * $unicorn.topology._DISTANCE_.Y
    containerH += (maxDepth + 1) * $unicorn.topology._NODE_.height
    containerH += $unicorn.topology._DISTANCE_.Y
    containerW = (options.left - 1) * $unicorn.topology._DISTANCE_.X
    containerW += options.left * $unicorn.topology._NODE_.width
    containerW += $unicorn.topology._DISTANCE_.X
    if containerW < $unicorn.topology._NODE_.root.width
      containerW = $unicorn.topology._NODE_.root.width
    target.css({width: containerW, height: containerH})

    if target.data("clickId")
      clkId = "cross_topology_node_id_#{target.data('clickId')}"
      clkEle = angular.element "##{clkId}"
      scrollLeft = target.scrollLeft()
      prePosition = parseInt(clkEle.css("left"))
      deltaLeft = parseInt(clkEle.attr("left")) - prePosition
      target.scrollLeft(deltaLeft + scrollLeft)
      angular.element(".cross-topology-node").each ->
        $this = angular.element(@)
        if $this.css("left") != "auto"
          eleLeft = parseInt($this.css("left"))
          $this.css("left", "#{eleLeft+deltaLeft}px")

    angular.element(".cross-topology-node").each ->
      $this = angular.element(@)
      if $this.css("left") == "auto"
        $this.css({
          left: "#{$this.attr('left')}px"
          top: "#{$this.attr('top')}px"
        }).slideDown()
      else
        $this.css({
          display: $this.attr("display")
        }).animate({
          left: "#{$this.attr('left')}px"
          top: "#{$this.attr('top')}px"
        })

    target.data("hostView", hostView)
