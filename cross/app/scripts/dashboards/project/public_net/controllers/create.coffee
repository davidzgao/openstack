'use strict'

###*
 # @ngdoc function
 # @name Cross.project.volume:VolumeCreateCtrl
 # @description
 # # VolumeCreateCtrl
 # Controller of the Cross
###
angular.module('Cross.project.public_net')
  .controller 'project.public_net.NetAllocateCtr', ($scope, $http, $window, $q,
                                         $state, $interval, $templateCache,
                                         $compile, $animate) ->
    serverUrl = $window.$CROSS.settings.serverURL
    (new NetCreateModal()).initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state})

    # NOTE(Liu Haobo):
    #if the in use resource is less then the quota set
    #  continue create resource
    #else
    #  it will call a reminder to warn user that quota is
    # not enough.
    projectId = $CROSS.person.project.id
    serverUrl = $CROSS.settings.serverURL
    quotas    = $http.get "#{serverUrl}/nova/os-quota-sets/#{projectId}?usage=true"
    httpRes = [quotas]
    if $CROSS.settings.use_neutron
      floatings = $http.get "#{serverUrl}/floatingips"
      httpRes.push floatings
    $q.all httpRes
      .then (res) ->
        if $CROSS.settings.use_neutron && res[1]
          floatingList = res[1].data
        if res[0]
          quota = res[0].data
          if floatingList
            floatingIPNum = 0
            floatingList.forEach (item) ->
              if item.tenant_id == projectId
                floatingIPNum += 1
          if quota.floating_ips['in_use'] >= quota.floating_ips['limit'] or floatingIPNum >= quota.floating_ips['limit']
            toastr.error _(["Sorry, you have no more quota to get new %s",\
              _ "FloatingIP"])
            $state.go "project.public_net"
      .catch (err) ->
        toastr.error _ (["Get server quota error: %s", err.data      .error_description])


    # initial images.
    floatingPool = $http.get "#{serverUrl}/os-floating-ip-pools"
    $q.all [floatingPool]
      .then (res) ->
        pools = res[0].data
        poolDef = []
        for pool in pools
          item =
            text: pool.name
            value: pool.name
          poolDef.push item
        if not poolDef.length
          poolDef.push {text: _("No Available IP Pool"), value: -1}
        $scope.modal.fields[0].default = poolDef
        $scope.form['pool'] = poolDef[0].value
      .catch (err) ->
        # TODO(Li Xipeng): Handle get quota list error.
        console.log err, "Failed to get images."


class NetCreateModal extends $cross.Modal
  title: "Allocate floating ip"
  slug: "floating_ip_create"
  single: true
  save: "allocate"

  fields: ->
    [{
      slug: 'pool'
      label: _("IP pool")
      tag: 'select'
      default: []
    }]

  handle: ($scope, options) ->
    $http = options.$http
    serverUrl = $CROSS.settings.serverURL
    tenantId = $CROSS.person.project.id
    form = $scope.form
    $state = options.$state
    if form['pool'] == -1
      $scope.tips['pool'] = _("No ip pool avaliable.")
      options.callback false
      return
    data =
      pool: form['pool']
      tenant_id: tenantId
    $http.post "#{serverUrl}/os-floating-ips", data
      .success ->
        options.callback false
        toastr.success _("Successfully allocate floating ip.")
        $state.go 'project.public_net', {}, {reload: true}
      .error (error)->
        toastr.error _("Failed to allocate floating ip.")
        options.callback false
