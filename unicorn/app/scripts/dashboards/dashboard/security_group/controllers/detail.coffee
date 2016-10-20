'use strict'

angular.module('Unicorn.dashboard.security_group')
  .controller 'dashboard.security_group.SecurityGroupDetailCtr', ($scope, $http, $window,
                                               $q, $stateParams, $state, $animate) ->

    $scope.detail_tabs = [
      {
        name: _('Overview'),
        url: 'dashboard.security_group.securityGroupId.overview',
        available: true
      }
    ]

    secGroupDetail = new $unicorn.DetailView()
    secGroupDetail.init($scope, {
      itemId: $stateParams.securityGroupId
      $state: $state
    })

  .controller 'dashboard.security_group.SecGroupOverviewCtr', ($scope, $http, $window, $q,
                                                 $stateParams, $state, $animate) ->

    $scope.note =
      securityGroupRule: _("security group rule")
      header:
        protocol: _("Protocol")
        port: _("Port")
        range: _("IP range")
        action: _("Action")
        direction: _('Direction')
        remote: _('Remote')
      title:
        ip: _("Must be CIDR.")
        port: _("Must be number")
      action:
        delete: _("Delete")
        add: _("Add")
        save: _("Save")
      slug: _("security group rule")
    serverUrl = $UNICORN.settings.serverURL

    $scope.currentId = $stateParams.securityGroupId

    if $scope.currentId
      $scope.detail_show = "detail_show"
    else
      $scope.detail_show = "detail_hide"
    $scope.batchEnableClass = 'btn-disable'

    checkSelect = ->
      angular.forEach $scope.securityGroups, (inst, index) ->
        if inst.isSelected == true and inst.id != $scope.currentId
          $scope.securityGroups[index].isSelected = false
        if inst.id == $scope.currentId
          $scope.securityGroups[index].isSelected = true
    checkSelect()

    $scope.panle_close = ->
      $animate.enabled(true)
      $state.go 'project.security_group'
      $scope.detail_show = false

    detailShow = ->
      container = angular.element('.ui-view-container')
      $scope.detailHeight = $(window).height() - container.offset().top
      $scope.detailHeight -= 50
      $scope.detailWidth = container.width() * 0.79

    detailShow()

    $window.onresize = ->
      detailShow()

    getRules = (callback) ->
      $scope.add_new_rule = 0
      $scope.rule_table_show = 0
      $scope.mode = if $UNICORN.settings.use_neutron then 'in-out' else 'default'
      $unicorn.networks.securityGroupGet $http, $scope.currentId, (err, data) ->
        if not err
          if data.rules.length
            $scope.rule_table_show = 1

          $scope.rules = data.rules
          counter = 0
          loop
            break if counter >= data.rules.length
            counter += 1
          if callback
            callback()
        else
          if callback
            callback()

    getRules()

    $scope.port_group = [
      {name: 'All TCP', value: "TCP, 1:65535, 0.0.0.0/0"},
      {name: 'All UDP', value: "UDP, 1:65535, 0.0.0.0/0"},
      {name: 'All ICMP', value: "ICMP, -1:-1, 0.0.0.0/0"},
      {name: 'SSH', value: "TCP, 22, 0.0.0.0/0"},
      {name: 'MySQL', value: "TCP, 3306, 0.0.0.0/0"},
      {name: 'DNS', value: "UDP, 53, 0.0.0.0/0"},
      {name: 'RDP', value: "TCP, 3389, 0.0.0.0/0"},
      {name: 'HTTP', value: "TCP, 80, 0.0.0.0/0"},
      {name: 'HTTPS', value: "TCP, 443, 0.0.0.0/0"},
      {name: 'POP3', value: "TCP, 110, 0.0.0.0/0"},
      {name: 'POP3S', value: "TCP, 995, 0.0.0.0/0"},
      {name: 'SMTP', value: "TCP, 25, 0.0.0.0/0"},
      {name: 'SMTPS', value: "TCP, 465, 0.0.0.0/0"},
      {name: 'IMAP', value: "TCP, 143, 0.0.0.0/0"},
      {name: 'IMAPS', value: "TCP, 993, 0.0.0.0/0"}
    ]

    $scope.protocols = [{
      text: 'TCP'
      value: 'TCP'
    }, {
      text: 'UDP'
      value: 'UDP'
    }, {
      text: 'ICMP'
      value: 'ICMP'
    }]
    $scope.directions = [{
      text: _('Ingress')
      value: 'ingress'
    }, {
      text: _('Egress')
      value: 'egress'
    }]
    $scope.rule_val =
      protocol: 'TCP'
      direction: 'ingress'

    $scope.selectExample = ($event) ->
      $this = $($event.target)
      key = $this.attr('key').split(',')
      $scope.rule_val.protocol = key[0]
      $scope.rule_val.port = key[1]
      $scope.rule_val.ip = key[2]
      $this.siblings().removeClass('active')
      $this.addClass('active')
      return true

    $scope.addRow = ->
      if !$scope.add_new_rule
        $scope.rule_table_show = true
        $scope.add_new_rule = true
        $scope.rule_ip_invalid = ''
        $scope.rule_port_invalid = ''
        $scope.rule_ip_placeholder = _('IP range')
        $scope.rule_port_placeholder = _('Port range')

    $scope.saveAddRule = ->
      tenantId = $UNICORN.person.project.id
      port = $scope.rule_val.port
      protocol = $scope.rule_val.protocol
      group_id = $scope.currentId
      cidr = $scope.rule_val.ip
      valid = true

      if protocol == 'ICMP'
        if !is_port_valid(port, 255, -1, true)
          valid = false
          $scope.rule_port_invalid = 'invalid'
          $scope.rule_port_placeholder = _('Must be range between -1-255.')
          $scope.rule_val.port = ''
      else
        if !is_port_valid(port, 65535)
            valid = false
            $scope.rule_port_invalid = 'invalid'
            $scope.rule_port_placeholder = _('Must be range between 1-65535.')
            $scope.rule_val.port = ''

      if !is_cidr_valid(cidr)
        valid = false
        $scope.rule_ip_invalid = 'invalid'
        $scope.rule_ip_placeholder = _('Must be cidr format.')
        $scope.rule_val.ip = ''

      if !valid
        return
      port = port.replace /(^\s*)|(\s*$)/g, ""
      port = port.split(':')
      data =
        ip_protocol: protocol
        from_port: port[0]
        to_port: if port.length == 2 then port[1] else port[0]
        parent_group_id: group_id
        cidr: cidr
        direction: $scope.rule_val.direction
        tenant_id: tenantId
      $unicorn.networks.securityGroupAddRule $http, data, (err, data) ->
        if not err
          getRules()
          toastr.success _("Successfully add rule")
        else
          toastr.error _("Failed to add rule")

    $scope.deleteAddRule = ->
      if $scope.add_new_rule
        if !$scope.rules.length
          $scope.rule_table_show = false
        $scope.add_new_rule = false
        $scope.rule_val =
          protocol: 'TCP'

    $scope.deleteRule = (item) ->
      $unicorn.networks.securityGroupRuleDelete $http, item.id, (err, data) ->
        if not err
          toastr.success _("Successfully delete rule")
          getRules()
        else
          toastr.error _("Failed to delete rule")

    $scope.validInput = (mode) ->
      if mode == 'port'
        max = 65535
        min = 1
        if $scope.rule_val.protocol == 'ICMP'
          max = 255
          min = -1
        if !is_port_valid($scope.rule_val.port, max, min)
          $scope.rule_port_invalid = 'invalid'
        else
          $scope.rule_port_invalid = ''
      else if mode == 'ip'
        if !is_cidr_valid($scope.rule_val.ip)
          $scope.rule_ip_invalid = 'invalid'
        else
          $scope.rule_ip_invalid = ''

    is_port_valid = (port, max, min, icmp) ->
      if !min
        min = 1
      if !port && port != 0
        return false
      else
        port = port.replace /(^\s*)|(\s*$)/g, ""
        p = port.split(':')
        if not angular.isNumber(Number(p[0]))
          return false
        else if icmp
          return true
        else if p.length == 2 && not angular.isNumber(Number(p[1]))
          return false
        else if p.length == 2 && (p[0] > p[1]) || p[0] < min || p[1] > max
          return false
      return true

    is_cidr_valid = (val) ->
      if not val
        return false
      val = val.replace(/^\s+|\s+$/g, '')
      reg = /^(((\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5]))(\/([0-9]|1[0-9]|2[0-9]|3[0-2]))?(\r|\n|\r\n)?){1,4}$/
      if reg.test(val)
        return true
      return false
