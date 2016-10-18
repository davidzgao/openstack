angular.module('Cross.services')
  .factory '$gossip', ["$injector", ($injector) ->
    # Get services from $injector.
    $rootScope     = $injector.get "$rootScope"
    $log           = $injector.get "$log"
    $timeout        = $injector.get "$timeout"
    $gossipService = $injector.get "$gossipService"

    # final variable
    TRY_TIME      = 5000
    RETRY         = 50

    # global variable
    BASE_URL = $CROSS.settings.gossipURL

    # initial message queue
    $rootScope.msgQueue = {}
    $rootScope.SET = {}


    closeConnection = ->
      if not $rootScope.CONN
        return false
      if timeoutId
        $timeout.cancel timeoutId
        timeoutId = null
      try
        $rootScope.CONN.close()
      catch e
        $log.error "Error about", e

    _filterMessage = (messager) ->
      messager = messager or {}
      if messager.tag == 'workflow'
        return false
      if not messager.payload or not messager.payload.id
        return false
      priority = 'success'
      if messager.priority != 'info'
        priority = 'error'
      message = _(messager.message)
      delete messager.message
      tag = messager.tag
      if messager.event.indexOf('instance.floating_ip') == 0
        name = messager.payload.name
        messager.payload.id = messager.meta.instance_id
        messager.payload.name = messager.meta.instance_name
        messager.meta.floating_ip = name
      messager =
        content: message
        object: "#{tag}-#{messager.payload.id}"
        priority: priority
        meta: messager
      if messager.meta.event == 'instance.create.start'
        messager.loading = true
      return messager

    startRealtime = (resouce_id) ->
      if not resouce_id
        return false
      region = $CROSS.settings.region
      message = "region.#{region}.change.resource.#{resouce_id}.state.up"
      if $rootScope.CONN and $rootScope.CONN.readyState
        $rootScope.CONN.send message
        return true
      $rootScope.SET[resouce_id] = message

    destroyRealtime = (resouce_id) ->
      if not resouce_id
        return false
      region = $CROSS.settings.region
      message = "region.#{region}.change.resource.#{resouce_id}.state.down"
      if $rootScope.CONN and $rootScope.CONN.readyState
        $rootScope.CONN.send message
        return true
      $rootScope.SET[resouce_id] = message

    connect = (person, onMessage) ->
      if not person
        return
      region = $CROSS.settings.region
      retry      = 0
      timeoutId  = null
      userId     = person.user.id
      messageURL = person.auth
      service    = "#{BASE_URL}/#{messageURL}H#{userId}H1H#{region}"

      _connect = () ->
        # connect to gossip
        if not $rootScope.gossip
          $rootScope.CONN = new SockJS(service)
          $log.debug "Connecting to gossip service..."

        # When connected
        $rootScope.CONN.onopen = ->
          retry = 0
          if timeoutId
            $timeout.cancel timeoutId
            timeoutId = null
          $log.debug "Connected to gossip service."
          # Send messages
          for resource of $rootScope.SET
            if $rootScope.SET[resource]
              $rootScope.CONN.send $rootScope.SET[resource]
              delete $rootScope.SET[resource]

        # On message
        $rootScope.CONN.onmessage = (ev) ->
          if not onMessage
            return false
          try
            messager = JSON.parse ev.data
          catch e
            $log.error "Error about", e
            return false
          onMessage messager
          # handle notifications
          if messager.message_type == 'notification'
            messager = _filterMessage messager
            if messager
              $gossipService.updateMessage messager
          else if messager.message_type == 'meter'
            $gossipService.receiveMeter messager

        # When closed
        $rootScope.CONN.onclose = (ws) ->
          $log.debug "Disconnected."
          if ws.code == 1000 and ws.wasClean
            return false
          if timeoutId
            $timeout.cancel timeoutId
            timeoutId = null
          $rootScope.CONN = null
          if retry < RETRY
            retry += 1
            timeoutId = $timeout _connect, TRY_TIME

      _connect()
    return {
      ##
      # initial gossip service.
      # @param {Function} onMessage
      ##
      connect: (onMessage) ->
        # call connect method.
        connect($CROSS.person, onMessage)
      ##
      # Close connection
      ##
      closeConnection: ->
        closeConnection()
      ##
      # Start to collect realtime monitoring data.
      # @param {String} resouce_id
      ##
      startRealtime: (resouce_id) ->
        startRealtime(resouce_id)
      ##
      # Stop to collect realtime monitoring data.
      # @param {String} resouce_id
      ##
      destroyRealtime: (resouce_id) ->
        destroyRealtime(resouce_id)
    }
  ]
  .factory '$gossipService', ["$rootScope", ($rootScope) ->
    _handleMessage = (message) ->
      message = message || {}
      if not toastr[message.priority]
        return
      opts = undefined
      if message.loading
        opts =
          iconClass: 'toast-loading'
          timeOut: 60000
      if not $rootScope.msgQueue[message.object]
        trs = toastr[message.priority](message.content, null, opts)
        objId = "_message-#{message.object}"
        trs.attr('id', objId)
        $rootScope.msgQueue[message.object] = objId
      else
        objId = $rootScope.msgQueue[message.object]
        obj = angular.element "##{objId}"
        if obj.length
          obj.removeClass 'toast-loading'
          obj.removeClass 'toast-info'
          obj.removeClass 'toast-success'
          obj.removeClass 'toast-warning'
          obj.removeClass 'toast-error'
          obj.addClass "toast-#{message.priority}"
          obj.html(message.content)
          if not message.loading
            if toastr.options.timeOut > 0
              setTimeout ->
                obj.slideUp()
                toastr.remove obj
                delete $rootScope.msgQueue[message.object]
              , toastr.options.timeOut
        else
          trs = toastr[message.priority](message.content, null, opts)
          objId = "_message-#{message.object}"
          trs.attr('id', objId)
          $rootScope.msgQueue[message.object] = objId

    return {
      receiveMessage: (message) ->
        _handleMessage message

      receiveMeter: (message) ->
        counter_name = null
        switch message.counter_name
          when 'cpu_util'
            counter_name = 'cpu_util'
          when 'memory.usage'
            counter_name = 'memory.usage'
          when 'disk.write.bytes.rate'
            counter_name = 'disk'
          when 'disk.read.bytes.rate'
            counter_name = 'disk'
          when 'network.incoming.bytes.rate'
            counter_name = 'network'
          when 'network.outgoing.bytes.rate'
            counter_name = 'network'
          when 'ceph.write.bytes.rate'
            counter_name = 'ceph.write'
          when 'ceph.read.bytes.rate'
            counter_name = 'ceph.read'
          when 'ceph.operations.rate'
            counter_name = 'ceph.operations'
          when 'ceph.util'
            counter_name = 'ceph.util'
        if not counter_name
          return false
        tag = "#{message.resource_id}.#{counter_name}"
        $rootScope.$broadcast "$gossipService.meter.#{tag}", message

      updateMessage: (message) ->
        _handleMessage message
        $rootScope.$broadcast "$gossipService.#{message.meta.tag}", message.meta
        switch message.meta.event
          when "instance.floating_ip.associate"
            message.meta.isInstance = true
            $rootScope.$broadcast "$gossipService.floating_ip", message.meta
          when "instance.floating_ip.disassociate"
            message.meta.isInstance = true
            $rootScope.$broadcast "$gossipService.floating_ip", message.meta
    }
  ]
