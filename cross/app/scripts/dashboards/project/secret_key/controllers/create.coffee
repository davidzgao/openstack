'use strict'

###*
 # @ngdoc function
 # @name Cross.project.volume:VolumeCreateCtrl
 # @description
 # # VolumeCreateCtrl
 # Controller of the Cross
###
angular.module('Cross.project.secret_key')
  .controller 'project.secret_key.KeypairCreateCtr', ($scope, $http, $window, $q,
                                         $state, $interval, $templateCache,
                                         $compile, $animate) ->
    $scope.note =
      import: _("Import public key")
    serverUrl = $window.$CROSS.settings.serverURL
    (new KeypairCreateModal()).initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state})
    $scope.modal.importKey = false
    $scope.modal.fields[1].type = 'hidden'
    $scope.importKey = ->
      if not $scope.modal.importKey
        $scope.modal.importKey = true
        $scope.note.import = _("Hide import public key")
      else
        $scope.modal.importKey = false
        $scope.note.import = _("Import public key")


class KeypairCreateModal extends $cross.Modal
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
        regex: [/^\w+$/, _("Please input letters, digits or underline.")]
    }, {
      slug: 'public_key'
      label: _("Public key")
      tag: 'textarea'
      restrictions:
        len: [1, 65537]
    }]

  handle: ($scope, options) ->
    $http = options.$http
    serverUrl = $CROSS.settings.serverURL
    form = $scope.form
    $state = options.$state
    data =
      name: form['name']
    if form['public_key']
      data['public_key'] = form['public_key']
    $http.post "#{serverUrl}/os-keypairs", data
      .success (keypair) ->
        options.callback false
        $state.go 'project.secret_key', {}, {reload: true}
        if keypair.private_key
          exp = new Blob([keypair.private_key],
          {
            type: "application/text;charset=utf-8"
          })
          saveAs(exp, "#{keypair.name}.pem")
      .error (error)->
        toastr.error _("Failed to create keypair.")
        options.callback false
