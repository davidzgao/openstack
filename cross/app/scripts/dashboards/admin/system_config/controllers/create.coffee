'use strict'

angular.module('Cross.admin.system_config')
  .controller 'admin.system_config.optionAction', ($scope, $http,
  $window, $q, $state) ->
    #pass
    state = $state
  .controller 'admin.system_config.optionEditCtr', ($scope, $http,
  $window, $q, $state) ->
    serverUrl = $window.$CROSS.settings.serverURL
    optionId = $state.params.optionId

    (new OptionEditModal()).initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state
    })

    $scope.note.modal.save = _ "Update"

    $scope.form['option_id'] = optionId
    $http.get "#{serverUrl}/options/#{optionId}"
      .success (data) ->
        $scope.form['key'] = data.key
        $scope.form['display_name'] = data.display_name
        # FIXME (liuhaobo): password is still displayed
        # in the packet, should do some optimizations
        # in the future.
        if data.key == 'email_sender_password'
          $scope.modal.fields[1].type = "password"
        $scope.form['value'] = data.value
        $scope.form['description'] = data.description
      .error (err) ->
        toastr.error _("Fail to get option")
        $state.go 'admin.system_config'
    $http.get "#{serverUrl}/option_groups"
      .success (data) ->
        groups = data.list
        avai = []
        for group in groups
          item =
            text: group.display_name
            value: group.id
          avai.push item

        $scope.modal.fields[3].default = avai
        $scope.form['group'] = avai[0].value


class OptionEditModal extends $cross.Modal
  title: 'Edit config option'
  slug: 'create_edit_option'
  single: true

  fields: ->
    [{
      slug: 'display_name'
      label: _ 'Name'
      tag: 'input'
      restrictions:
        required: false
        len: [1, 32]
      type: 'disable'
    }, {
      slug: 'value'
      label: _ 'Value'
      tag: 'input'
      restrictions:
        required: true
        len: [1, 64]
    }, {
      slug: 'option_id'
      label: _ 'Option id'
      tag: 'input'
      type: 'hidden'
    }, {
      slug: 'description'
      label: _ 'Description'
      tag: 'input'
      type: 'disable'
    }]

  handle: ($scope, options) ->
    param = $scope.form
    param['group_id'] = param['group']
    $window = options.$window
    $http = options.$http
    $state = options.$state

    serverUrl = $window.$CROSS.settings.serverURL

    $http.put "#{serverUrl}/options/#{param['option_id']}", param
      .success (data) ->
        toastr.success _ "Successuflly to update option!"
        $state.go 'admin.system_config', {}, {reload: true}
      .error (err) ->
        toastr.error _ "Failed to update option!"
        $state.go 'admin.system_config'
