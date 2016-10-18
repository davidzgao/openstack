'use strict'

###*
 # @ngdoc function
 # @name Cross.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the Cross
###
angular.module("Cross.project.overview")
  .controller "project.overview.OverviewCtr", ($scope, $http, $q, $window) ->
    # Initial note.
    $scope.note =
      create:
        title: _("Resource Create")
        create_instance: _("Create Instance")
        create_volume: _("Create Volume")
        create_floating: _("Create Floating")
      usage:
        lead: _("Quota summary")
        instance: _("Instance")
        vcpu: _("CPU")
        ram: _("Memory capacity")
        volume: _("Volume")
        volumeCapacity: _("Volume capacity")
        floatingIP: _("Public IP")
        keyPair: _("Key pair")
        securityGroup: _("Security group")
        securityGroupRule: _("Security group rule")
        snapshot: _("Volume snapshot")
        update: _("Update Quota")
      unit:
        core: _("cores")
        num: _("Num")
        gb: _("GB")
      log:
        lead: _("Recent log")
        empty: _ "No operation logs."
        operator: _("Operator")
        more: _("Detail")

    stats = {}
    serverUrl = $CROSS.settings.serverURL

    ###
    #
    # Take care of person data.
    ###
    initialView = (callback) ->
      if $CROSS.person
        projectId = $CROSS.person.project.id
        callback(projectId)
      else
        $http.get "#{serverUrl}/auth"
          .success (person) ->
            $CROSS.person = person
            callback(person.project.id)
          .error (err) ->
            console.warn "Could not get user data:", err
            toastr.warn _("Could not get user data, please refresh page.")

    ###*
    #
    # Get quota data.
    ###

    initialQuota = (projectId) ->
      quotas = $http.get "#{serverUrl}/nova/os-quota-sets/#{projectId}?usage=true"
      httpRes = [quotas]
      if $CROSS.settings.use_neutron
        floatings = $http.get "#{serverUrl}/floatingips"
        httpRes.push floatings
        useNeutron = true
      else
        useNeutron = false
      $q.all httpRes
        .then (res, err) ->
          if res[1]
            floatingList = res[1].data
          if res
            quota = res[0].data

            if floatingList
              floatingIPNum = 0
              floatingList.forEach (item) ->
                if item.tenant_id == projectId
                  floatingIPNum += 1

            stats.vcpu = 0
            stats.vcpuTotal = quota.cores.limit
            stats.vcpuUsed = quota.cores.in_use
            if stats.vcpuTotal and stats.vcpuTotal != -1
              stats.vcpu = 100 * stats.vcpuUsed / stats.vcpuTotal
              stats.vcpu = Math.round stats.vcpu
              stats.vcpuTotal = "#{stats.vcpuTotal}"
            else if stats.vcpuTotal == -1
              stats.vcpuTotal = _("Unlimited")
            stats.vcpuState = 'ok'
            if stats.vcpu > utils._WARN_THREATHOLD_
              stats.vcpuState = 'warn'

            # handle instance usage.
            stats.instance = 0
            stats.instanceTotal = quota.instances.limit
            stats.instanceUsed = quota.instances.in_use
            if stats.instanceTotal and stats.instanceTotal != -1
              stats.instance = 100 * stats.instanceUsed / stats.instanceTotal
              stats.instance = Math.round stats.instance
            else if stats.instanceTotal == -1
              stats.instanceTotal = _("Unlimited")
            stats.instanceState = 'ok'
            if stats.instance > utils._WARN_THREATHOLD_
              stats.instanceState = 'warn'

            # handle memory usage.
            stats.ram = 0
            stats.ramTotal = quota.ram.limit
            stats.ramUsed = quota.ram.in_use
            if stats.ramTotal and stats.ramTotal != -1
              stats.ram = 100 * stats.ramUsed / stats.ramTotal
              stats.ram = Math.round stats.ram
              stats.ramTotal = $cross.utils.rand(stats.ramTotal / 1024)
            else if stats.ramTotal == -1
              stats.ramTotal = _("Unlimited")
            stats.ramState = 'ok'
            if stats.ram > utils._WARN_THREATHOLD_
              stats.ramState = 'warn'
            stats.ramUsed = $cross.utils.rand(stats.ramUsed / 1024)

            # handle floating ip usage.
            stats.floatingIP = 0
            stats.floatingIPTotal = quota.floating_ips.limit
            if useNeutron == false
              stats.floatingIPUsed = quota.floating_ips.in_use
            else
              stats.floatingIPUsed = floatingIPNum
            if stats.floatingIPTotal and stats.floatingIPTotal != -1
              stats.floatingIP = 100 * stats.floatingIPUsed
              stats.floatingIP /= stats.floatingIPTotal
              stats.floatingIP = Math.round stats.floatingIP
            else if stats.floatingIPTotal == -1
              stats.floatingIPTotal = _("Unlimited")
            stats.floatingIPState = 'ok'
            if stats.floatingIP > utils._WARN_THREATHOLD_
              stats.floatingIPState = 'warn'

            # handle key pair usage.
            stats.keyPair = 0
            stats.keyPairTotal = quota.key_pairs.limit
            stats.keyPairUsed = quota.key_pairs.in_use
            if stats.keyPairTotal and stats.keyPairTotal != -1
              stats.keyPair = 100 * stats.keyPairUsed
              stats.keyPair /= stats.keyPairTotal
              stats.keyPair = Math.round stats.keyPair
            else if stats.keyPairTotal == -1
              stats.keyPairTotal = _("Unlimited")
            stats.keyPairState = 'ok'
            if stats.keyPair > utils._WARN_THREATHOLD_
              stats.keyPairState = 'warn'

            # handle security group usage.
            stats.securityGroup = 0
            stats.securityGroupTotal = quota.security_groups.limit
            stats.securityGroupUsed = quota.security_groups.in_use
            if stats.securityGroupTotal and stats.securityGroupTotal != -1
              stats.securityGroup = 100 * stats.securityGroupUsed
              stats.securityGroup /= stats.securityGroupTotal
              stats.securityGroup = Math.round stats.securityGroup
            else if stats.securityGroupTotal == -1
              stats.securityGroupRuleTotal = _("Unlimited")
            stats.securityGroupState = 'ok'
            if stats.securityGroup > utils._WARN_THREATHOLD_
              stats.securityGroupState = 'warn'

            # handle security group rule usage.
            stats.securityGroupRule = 0
            stats.securityGroupRuleTotal = quota.security_group_rules.limit
            stats.securityGroupRuleUsed = quota.security_group_rules.in_use
            if stats.securityGroupRuleTotal and stats.securityGroupRuleTotal != -1
              stats.securityGroupRule = 100 * stats.securityGroupRuleUsed
              stats.securityGroupRule /= stats.securityGroupRuleTotal
              stats.securityGroupRule = Math.round stats.securityGroupRule
            else if stats.securityGroupRuleTotal == -1
              stats.securityGroupRuleTotal = _("Unlimited")
            stats.securityGroupRuleState = 'ok'
            if stats.securityGroupRule > utils._WARN_THREATHOLD_
              stats.securityGroupRuleState = 'warn'
            $scope.usage = stats
          else
            console.log "Get server quota error: #{err}"
            toastr.error _ "Get server quota error:"

      $http.get "#{serverUrl}/cinder/os-quota-sets/#{projectId}?usage=true"
        .success (quota) ->
          # handle volume usage.
          stats.volume = 0
          stats.volumeTotal = quota.volumes.limit
          stats.volumeUsed = quota.volumes.in_use
          if stats.volumeTotal and stats.volumeTotal != -1
            stats.volume = 100 * stats.volumeUsed
            stats.volume /= stats.volumeTotal
            stats.volume = Math.round stats.volume
          else if stats.volumeTotal == -1
            stats.volumeTotal = _("Unlimited")
          stats.volumeState = 'ok'
          if stats.volume > utils._WARN_THREATHOLD_
            stats.volumeState = 'warn'

          # handle snapshot usage.
          stats.snapshot = 0
          stats.snapshotTotal = quota.snapshots.limit
          stats.snapshotUsed = quota.snapshots.in_use
          if stats.snapshotTotal and stats.snapshotTotal != -1
            stats.snapshot = 100 * stats.snapshotUsed
            stats.snapshot /= stats.snapshotTotal
            stats.snapshot = Math.round stats.snapshot
          else if stats.snapshotTotal == -1
            stats.snapshotTotal = _("Unlimited")
          stats.snapshotState = 'ok'
          if stats.snapshot > utils._WARN_THREATHOLD_
            stats.snapshotState = 'warn'

          # handle volume capacity usage.
          stats.volumeCapacity = 0
          stats.volumeCapacityTotal = quota.gigabytes.limit
          stats.volumeCapacityUsed = quota.gigabytes.in_use
          if stats.volumeCapacityTotal and stats.volumeCapacityTotal != -1
            stats.volumeCapacity = 100 * stats.volumeCapacityUsed
            stats.volumeCapacity /= stats.volumeCapacityTotal
            stats.volumeCapacity = Math.round stats.volumeCapacity
            stats.volumeCapacityTotal = stats.volumeCapacityTotal
          else if stats.volumeCapacityTotal == -1
            stats.volumeCapacityTotal = _("Unlimited")
          stats.volumeCapacityState = 'ok'
          if stats.volumeCapacity > utils._WARN_THREATHOLD_
            stats.volumeCapacityState = 'warn'
          stats.volumeCapacityUsed = stats.volumeCapacityUsed
        .error (error) ->
          console.log "Get volume quota error: #{error}"

    initialView(initialQuota)

    $scope.logLoding = true
    $http.get("#{serverUrl}/events", {
      params:
        limit: 12
    }).success (logs) ->
        $scope.logLoding = false
        logs = $cross.message.parseMessage logs
        $cross.message.addUserName logs, $http, $q, serverUrl, (messages) ->
          $scope.logs =  messages
      .error (error) ->
        $scope.logLoding = false

    return


utils =
  # Warn threathold.
  _WARN_THREATHOLD_: 90
