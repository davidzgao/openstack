'use strict'

$unicorn.networks =
  listNetworks: ($http, queryOpts, callback) ->
    serverURL = $UNICORN.settings.serverURL
    use_neutron = $UNICORN.settings.use_neutron or false
    hash = 'os-networks'
    if use_neutron
      hash = 'networks'
    query =
      params: queryOpts
    $http.get "#{serverURL}/#{hash}", query
      .success (networks, status, headers) ->
        callback undefined, networks
      .error (err) ->
        callback err

  listSecurityGroups: ($http, queryOpts, callback) ->
    serverURL = $UNICORN.settings.serverURL
    use_neutron = $UNICORN.settings.use_neutron or false
    hash = 'os-security-groups'
    if use_neutron
      hash = 'security-groups'
    query =
      params: queryOpts
    $http.get "#{serverURL}/#{hash}", query
      .success (securityGroups, status, headers) ->
        callback undefined, securityGroups
      .error (err) ->
        callback err

  securityGroupCreate: ($http, data, callback) ->
    serverURL = $UNICORN.settings.serverURL
    use_neutron = $UNICORN.settings.use_neutron or false
    hash = 'os-security-groups'
    if use_neutron
      hash = 'security-groups'
    $http.post("#{serverURL}/#{hash}", data)
      .success (securityGroup, status, headers) ->
        callback undefined, securityGroup
      .error (err) ->
        callback err

  securityGroupDelete: ($http, id, callback) ->
    serverURL = $UNICORN.settings.serverURL
    use_neutron = $UNICORN.settings.use_neutron or false
    hash = 'os-security-groups'
    if use_neutron
      hash = 'security-groups'
    $http.delete("#{serverURL}/#{hash}/#{id}")
      .success (securityGroup, status, headers) ->
        callback undefined, securityGroup
      .error (err) ->
        callback err

  securityGroupGet: ($http, id, callback) ->
    serverURL = $UNICORN.settings.serverURL
    use_neutron = $UNICORN.settings.use_neutron or false
    hash = 'os-security-groups'
    if use_neutron
      hash = 'security-groups'
    $http.get("#{serverURL}/#{hash}/#{id}")
      .success (securityGroup, status, headers) ->
        if use_neutron
          rules = securityGroup.security_group_rules
          for rule in rules
            if not rule.protocol
              rule.protocol = _('Any')
            if not rule.remote_ip_prefix
              if rule.direction == 'ingress'
                rule.remote_ip_prefix = _('default')
              else if rule.direction == 'egress'
                if rule.ethertype == 'IPv6'
                  rule.remote_ip_prefix = '::/0 (CIDR)'
                else if rule.ethertype == 'IPv4'
                  rule.remote_ip_prefix = '0.0.0.0/0 (CIDR)'
            else
              rule.remote_ip_prefix = "#{rule.remote_ip_prefix} (CIDR)"
            if rule.port_range_max == null and rule.port_range_min == null
              rule.port_range_max = '-'
              rule.port_range_min = '-'
            else
              if rule.port_range_max == null
                rule.port_range_max = _('Any')
              if rule.port_range_min == null
                rule.port_range_min = _('Any')
          securityGroup.rules = rules
          delete securityGroup.security_group_rules
        callback undefined, securityGroup
      .error (err) ->
        callback err

  securityGroupAddRule: ($http, data, callback) ->
    serverURL = $UNICORN.settings.serverURL
    use_neutron = $UNICORN.settings.use_neutron or false
    hash = 'os-security-group-rules'
    body = {}
    if use_neutron
      hash = 'security-group-rules'
      body =
        direction: data.direction
        remote_ip_prefix: data.cidr
        protocol: data.ip_protocol
        security_group_id: data.parent_group_id
      if data.ip_protocol.toLowerCase() == 'icmp'
        if parseInt(data.from_port) == -1
          body.port_range_min = undefined
        else
          body.port_range_max = data.from_port
        if parseInt(data.to_port) == -1
          body.port_range_max = undefined
        else
          body.port_range_max = data.to_port
      else
        body.port_range_max = data.to_port
        body.port_range_min = data.from_port
    else
      body = data
      delete body.direction
    $http.post("#{serverURL}/#{hash}", body)
      .success (rule, status, headers) ->
        callback undefined, rule
      .error (err) ->
        callback err

  securityGroupRuleDelete: ($http, id, callback) ->
    serverURL = $UNICORN.settings.serverURL
    use_neutron = $UNICORN.settings.use_neutron or false
    hash = 'os-security-group-rules'
    if use_neutron
      hash = 'security-group-rules'
    $http.delete("#{serverURL}/#{hash}/#{id}")
      .success (securityGroupRule, status, headers) ->
        callback undefined, securityGroupRule
      .error (err) ->
        callback err
