$cross.gossip =
  TRY_TIME: 5000
  retry: 10
  RETRY_DEFAULT: 10
  retryTimeout: 5000
  conn: undefined
  msgQueue: {}
  debug: window.$CROSS.settings.debug
  close: ->
    $cross.gossip.retry = 0
    if $cross.gossip.conn
      try
        $cross.gossip.conn.close()
      catch e
        console.error "Failed to connect to gossip", e
      finally
        $cross.gossip.conn = undefined

  _filterMessage: (messager) ->
    messager = messager || {}
    if not messager.payload || not messager.payload.id
      return false
    priority = 'success'
    if messager.priority != 'info'
      priority = 'error'
    message = _(messager.message)
    delete messager.message
    tag = messager.tag
    messager =
      content: message
      object: "#{tag}-#{messager.payload.id}"
      priority: priority
      meta: messager
    if messager.meta.event == 'instance.create.start'
      messager.loading = true
    return messager
