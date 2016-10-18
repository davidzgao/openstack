'use strict'

###*
 # @ngdoc function
 # @name Cross.project.volume:VolumeCreateCtrl
 # @description
 # # VolumeCreateCtrl
 # Controller of the Cross
###
angular.module('Cross.project.security_group')
  .controller 'project.security_group.SecurityGroupCreateCtr', ($scope, $http, $window, $q,
                                         $state, $interval, $templateCache,
                                         $compile, $animate) ->
    serverUrl = $window.$CROSS.settings.serverURL
    (new SecurityGroupCreateModal()).initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state})

    # NOTE(Liu Haobo):
    # if the in use resource is less then the quota set
    #   continue create resource
    # else
    #   it will call a reminder to warn user that quota is
    #  not enough.
    projectId = $CROSS.person.project.id
    serverUrl = $CROSS.settings.serverURL
    $http.get "#{serverUrl}/nova/os-quota-sets/#{projectId}?usage=true"
      .success (quota) ->
        if quota.security_groups['in_use'] >= quota.security_groups['limit']
          toastr.error _(["Sorry, you have no more quota to get new %s",\
            _ "security_group"])
          $state.go "project.security_group"
      .error (err) ->
        console.log err


class SecurityGroupCreateModal extends $cross.Modal
  title: "Create security group"
  slug: "security_group_create"
  single: true

  fields: ->
    [{
      slug: 'name'
      label: _("Name")
      tag: 'input'
      restrictions:
        required: true
        regx: [/^/, _("")]
    }, {
      slug: 'description'
      label: _("Description")
      tag: 'textarea'
      restrictions:
        required: true
        len: [1, 255]
    }]

  handle: ($scope, options) ->
    $http = options.$http
    serverUrl = $CROSS.settings.serverURL
    tenantId = $CROSS.person.project.id
    form = $scope.form
    $state = options.$state
    data =
      name: form['name']
    if form['description']
      data['description'] = form['description']
    data['tenant_id'] = tenantId
    $cross.networks.securityGroupCreate $http, data, (err, securityGroup) ->
      if not err
        options.callback false
        $state.go 'project.security_group', {}, {reload: true}
      else
        toastr.error _("Failed to create security group.")
        options.callback false
