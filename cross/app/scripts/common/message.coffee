$cross.message =
  addUserName: (messages, $http, $q, serverUrl, callback) ->
    user_ids = []
    for msg in messages
      traits = msg.traits or {}
      user_id = traits.context_user_id
      if user_id and user_id not in user_ids
        user_ids.push user_id
    user_http = $http.get "#{serverUrl}/users/query", {
      params:
        ids: JSON.stringify user_ids
        fields: '["name"]'
    }
    user_http.success (users)->
      for msg in messages
        msg.user_name = if users[msg.user_id] then users[msg.user_id].name else msg.user_id
      callback(messages)

  _parseTrait: (msg) ->
    traits = {}
    for trait in msg.traits || []
      traits[trait.name] = trait.value
    return traits

  _parse: (action, state, message, resource_type) ->
    traits = $cross.message._parseTrait message
    return {
      resource_type: resource_type
      state: state
      event_type: message.event_type
      traits: traits
      user_id: message.user_id
      project_id: message.project_id
      generated: message.generated
      action_msg: _(action)
    }

  parseMessage: (messages) ->
    msgs = []
    _parse = $cross.message._parse
    for msg in messages
      switch msg.event_type
        when 'compute.instance.create.end'
          msgs.push(_parse "create instance", 'success', msg, 'instance')
        when 'compute.instance.delete.end'
          msgs.push(_parse "delete instance", 'success', msg, 'instance')
        when 'compute.instance.reboot.end'
          msgs.push(_parse "reboot instance", 'success', msg, 'instance')
        when 'compute.instance.shutdown.end'
          msgs.push(_parse "shutdow instance", 'success', msg, 'instance')
        when 'compute.instance.power_off.end'
          msgs.push(_parse "power off instance", 'success', msg, 'instance')
        when 'compute.instance.power_on.end'
          msgs.push(_parse "power on instance", 'success', msg, 'instance')
        when 'compute.instance.suspend'
          msgs.push(_parse "suspend instance", 'success', msg, 'instance')
        when 'compute.instance.resume'
          msgs.push(_parse "resume instance", 'success', msg, 'instance')
        when 'compute.instance.reboot.end'
          msgs.push(_parse "snapshot instance", 'success', msg, 'instance')
        when 'compute.instance.finish_resize.end'
          msgs.push(_parse "resize instance", 'success', msg, 'instance')
        when 'compute.instance.volume.attach'
          msgs.push(_parse "attach volume to instance", 'success', msg, 'instance')
        when 'compute.instance.volume.detach'
          msgs.push(_parse "detach volume from instance", 'success', msg, 'instance')
        when 'network.floating_ip.associate'
          msgs.push(_parse "associate floating ip", 'success', msg, 'floating_ip')
        when 'network.floating_ip.disassociate'
          msgs.push(_parse "disassociate floating ip", 'success', msg, 'floating_ip')
        when 'network.floating_ip.allocate'
          msgs.push(_parse "allocate floating ip", 'success', msg, 'floating_ip')
        when 'network.floating_ip.deallocate'
          msgs.push(_parse "deallocate floating ip", 'success', msg, 'floating_ip')
        when 'volume.create.end'
          msgs.push(_parse "create volume", 'success', msg, 'volume')
        when 'volume.delete.end'
          msgs.push(_parse "delete volume", 'success', msg, 'volume')
        when 'snapshot.create.end'
          msgs.push(_parse "create volume snapshot", 'success', msg, 'volume_snapshot')
        when 'snapshot.delete.end'
          msgs.push(_parse "delete volume snapshot", 'success', msg, 'volume_snapshot')
        when 'image.activate'
          msgs.push(_parse "create image", 'success', msg, 'image')
        when 'image.delete'
          msgs.push(_parse "delete image", 'success', msg, 'image')
        when 'network.create.end'
          msgs.push(_parse "create network", 'success', msg, 'network')
        when 'network.delete.end'
          msgs.push(_parse "delete network", 'success', msg, 'network')
        when 'floatingip.create.end'
          msgs.push(_parse "allocate floating ip", 'success', msg, 'floating_ip')
        when 'floatingip.delete.end'
          msgs.push(_parse "deallocate floating ip", 'success', msg, 'floating_ip')
        when 'subnet.create.end'
          msgs.push(_parse "create subnet", 'success', msg, 'subnet')
        when 'subnet.delete.end'
          msgs.push(_parse "delete subnet", 'success', msg, 'subnet')
        when 'port.create.end'
          msgs.push(_parse "create port", 'success', msg, 'port')
        when 'port.delete.end'
          msgs.push(_parse "delete port", 'success', msg, 'port')
        when 'terminate_instance'
          msgs.push(_parse "delete instance", 'error', msg, 'instance')
        when 'stop_instance'
          msgs.push(_parse "stop instance", 'error', msg, 'instance')
        when 'start_instance'
          msgs.push(_parse "start instance", 'error', msg, 'instance')
        when 'soft_delete_instance'
          msgs.push(_parse "soft delet instance", 'error', msg, 'instance')
        when 'power_on_instance'
          msgs.push(_parse "power on instance", 'error', msg, 'instance')
        when 'power_off_instance'
          msgs.push(_parse "power off instance", 'error', msg, 'instance')
        when 'reboot_instance'
          msgs.push(_parse "reboot instance", 'error', msg, 'instance')
        when 'snapshot_instance'
          msgs.push(_parse "snapshot instance", 'error', msg, 'instance')
        when 'resize_instance'
          msgs.push(_parse "resize instance", 'error', msg, 'instance')
        when 'finish_resize'
          msgs.push(_parse "resize instance", 'error', msg, 'instance')
        when 'run_instance'
          msgs.push(_parse "create instance", 'error', msg, 'instance')
        when 'pause_instance'
          msgs.push(_parse "pause instance", 'error', msg, 'instance')
        when 'unpause_instance'
          msgs.push(_parse "unpause instance", 'error', msg, 'instance')
        when 'attach_volume'
          msgs.push(_parse "attach volume to instance", 'error', msg, 'instance')
        when 'detach_volume'
          msgs.push(_parse "detach volume from instance", 'error', msg, 'instance')
        else continue
    return msgs
