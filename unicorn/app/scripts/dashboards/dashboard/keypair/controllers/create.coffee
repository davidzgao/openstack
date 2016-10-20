'use strict'

###*
 # @ngdoc function
 # @name Unicorn.project.volume:VolumeCreateCtrl
 # @description
 # # VolumeCreateCtrl
 # Controller of the Unicorn
###
angular.module('Unicorn.dashboard.keypair')
  .controller 'dashboard.keypair.KeypairCreateCtr', ($scope, $http,
  $window, $q, $state) ->
    $scope.note =
      import: _("Import public key")
    serverUrl = $window.$UNICORN.settings.serverURL
    (new KeypairCreateModal()).initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state})
    $scope.modal.importKey = false
    $scope.importKey = ->
      if not $scope.modal.importKey
        $scope.modal.importKey = true
        $scope.note.import = _("Hide import public key")
      else
        $scope.modal.importKey = false
        $scope.note.import = _("Import public key")


class KeypairCreateModal extends $unicorn.Modal
  title: "Create keypair"
  slug: "keypair_create"
  single: true

  fields: ->
    [{
      slug: 'name'
      label: _("Name")
      tag: 'input'
      restrictions:
        required: true
        len: [1, 32]
        regex: [/^\w+$/, _("Please input letters, digits or underline.")]
    }, {
      slug: 'public_key'
      label: _("Public key")
      tag: 'textarea'
      restrictions:
        len: [1, 65535]
    }]

  handle: ($scope, options) ->
    $http = options.$http
    $window = options.$window
    serverUrl = $window.$UNICORN.settings.serverURL
    form = $scope.form
    $state = options.$state
    data =
      name: form['name']
    if form['public_key']
      data['public_key'] = form['public_key']
    $http.post "#{serverUrl}/os-keypairs", data
      .success (keypair) ->
        if keypair.private_key
          exp = new Blob([keypair.private_key],
          {
            type: "application/text;charset=utf-8"
          })
          saveAs(exp, "#{keypair.name}.pem")
        options.callback false
        $state.go 'dashboard.keypair', {}, {reload: true}
      .error (error)->
        toastr.error _("Failed to create keypair.")
        options.callback false
