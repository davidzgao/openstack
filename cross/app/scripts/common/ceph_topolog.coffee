$cross.ceph =
  drawLink: (node, target, options) ->
    children = node.children_nodes
    if not children or not children.length
      return

    XMLNS = 'xmlns="http://www.w3.org/2000/svg"'
    VERSION = 'version="1.1"'
    STROKE_WIDTH = 2
    index = 0
    curr_x = 0
    pre_x = 0
    len = children.length

    # caculate width, height, initial line path.
    firstChildID = children[0].id
    lastChildID = children[len - 1].id
    $firstChildID = "#ceph-node-#{firstChildID}"
    $lastChildID = "#ceph-node-#{lastChildID}"
    firstChild = angular.element("#{$firstChildID}")
    lastChild = angular.element("#{$lastChildID}")
    width = parseInt(lastChild.css("left"))
    width -= parseInt(firstChild.css("left"))
    width += STROKE_WIDTH
    height = $cross.topology._DISTANCE_.Y
    d = "M#{width/2} 0 L#{width/2} #{height/2}"
    path = "<path d='#{d}' />"
    d = "M0 #{height/2} L#{width} #{height/2}"
    path += "<path d='#{d}' />"
    childHeight = 0
    for child in children
      childID = "ceph-node-#{child.id}"
      cNode = angular.element("##{childID}")
      childHeight = parseInt(cNode.css('height'))
      curr_x = parseInt(cNode.css("left"))
      if index == 0
        pre_x = curr_x - STROKE_WIDTH / 2
      d = "M#{curr_x-pre_x} #{height/2} L#{curr_x-pre_x} #{height}"
      path += "<path d='#{d}' />"
      index += 1
    lineId = "svg-ceph-node-#{node.id}"

    # Remove svg dom as it does not support jquery.html(path)
    if angular.element("##{lineId}").length
      angular.element("##{lineId}").remove()

    liner_str = "<svg class='cross-topology-line' #{XMLNS} #{VERSION}>"
    liner_str += path + '</svg>'
    liner = angular.element(liner_str)
    liner.attr({id: lineId}).appendTo target

    left = parseInt(firstChild.css("left"))
    if node.type == 'host'
      left += $cross.topology._NODE_.width / 2 - 8
    else if node.type == 'root'
      left += $cross.topology._NODE_.width / 2
    bottom = parseInt(firstChild.css("bottom"))
    bottom += childHeight
    liner.attr({left: left, bottom: bottom})
      .css({
        width: width
        height: height
        position: 'absolute'
        left: left
        bottom: bottom
      }).slideDown()

  drawNode: (node, area, pattern, noRack) ->
    paceWidth = 80 * 15
    nodeElement = angular.element('<div/>')
    nodeElement.attr("title", node.name)
    nodeElement.addClass(node.type)
    nodeElement.addClass("storage-node")
    nodeElement.id = node.type + '_' + node.id
    nodeElement.attr("id", "ceph-node-#{node.id}")
    if node.type == 'osd'
      pattern += 8
    nodeElement.css({left: pattern})
    verbose = node.name
    if verbose.length > 20
      verbose = node.name.slice(0, 15) + '...' + node.name.slice(-8)
    nodeInner = "<div class='node-bg'></div><div class='node-title'>#{node.type}: #{verbose}</div>"
    nodeElement.html(nodeInner)
    if node.type == 'root' and noRack == true
      area.css({marginTop: -40})
      nodeElement.css({bottom: 180})
    nodeElement.appendTo(area)

  renderNodes: (nodes, area) ->
    paceWidth = 80 * 1.8
    paceHeight = 64 * 2

    osdCounts = 0
    hostCounts = 0
    rackCounts = 0
    rootSubNodesPattern = []

    area.html()

    if (nodes.children.length > 0)
      noRack = true
      for contin in nodes.children
        if contin.type == 'rack'
          noRack = false
      sec_level_nodes = nodes.children_nodes
      for node, i in sec_level_nodes
        if node.children.length > 0
          three_level_nodes = node.children_nodes
          if node.type == 'rack'
            rack = node
            for host, j in rack.children
              for osd, k in host.children
                osdPattern = osdCounts * paceWidth
                $cross.ceph.drawNode(osd, area, osdPattern)
                osdCounts += 1
              hostPattern = (host.children.length * paceWidth)\
              (hostCounts + 1) - (paceWidth)
              $cross.ceph.drawNode(host, area, hostPattern)
              hostCounts += 1
            $cross.ceph.drawLink(rack, area)
            rackPattern = (rack.children.length * paceWidth)\
            * (rackCounts + 1) - paceWidth
            $cross.ceph.drawNode(rack, area, rackPattern / 2)
            rackCounts += 1
          else if node.type == 'host'
            host = node
            for osd , j in host.children_nodes
              $cross.ceph.drawNode(osd, area,
              osdCounts * paceWidth)
              osdCounts += 1
            $cross.ceph.drawLink(host, area)
            hostPattern = (osdCounts - host.children.length)\
            * paceWidth + ((host.children.length - 1) *\
            paceWidth) / 2
            rootSubNodesPattern.push hostPattern
            $cross.ceph.drawNode(host, area, hostPattern)
      fabric = angular.element("#ceph-topology")
      countLength = osdCounts * paceWidth
      if fabric.width() > countLength
        offset = (fabric.width() - osdCounts * paceWidth) / 2
        fabric.css("margin-left", offset + "px")
      root = nodes
      for leftDis, index in rootSubNodesPattern
        if index == 0
          minLeft = leftDis
        if index == rootSubNodesPattern.length - 1
          maxLeft = leftDis
      rootPattern = (maxLeft - minLeft) / 2 + minLeft
      if osdCounts == 1
        rootPattern = (osdCounts * paceWidth) / 2
      $cross.ceph.drawLink(root, area)
      $cross.ceph.drawNode(root, area, rootPattern, noRack)
