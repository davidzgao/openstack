'use strict'

###*
 # @ngdoc function
 # @name Unicorn.project.volume:VolumeCreateCtrl
 # @description
 # # VolumeCreateCtrl
 # Controller of the Unicorn
###
angular.module('Unicorn.dashboard.security_group')
  .controller 'dashboard.security_group.SecurityGroupCreateCtr', ($scope, $http, $window, $q,
                                         $state, $interval, $templateCache,
                                         $compile, $animate) ->
    serverUrl = $UNICORN.settings.serverURL
    (new SecurityGroupCreateModal()).initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state})


class SecurityGroupCreateModal extends $unicorn.Modal
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
        len: [0, 255]
    }]

  handle: ($scope, options) ->
    $http = options.$http
    serverUrl = $UNICORN.settings.serverURL
    form = $scope.form
    $state = options.$state
    data =
      name: form['name']
    if form['description']
      data['description'] = form['description']
    $unicorn.networks.securityGroupCreate $http, data, (err, securityGroup) ->
      if not err
        options.callback false
        toastr.success _("Successfully create security group: ") + form['name']
        $state.go 'dashboard.security_group', {}, {reload: true}
      else
        toastr.error _("Failed to create security group: ") + form['name']
        options.callback false
