'use strict'

angular.module('Unicorn.dashboard')
  .controller 'dashboard.feedback.FeedbackCreateCtr', ($scope, $http,
  $window, $q, $state) ->
    feedbackCreateModal = new FeedbackCreateModal()
    feedbackCreateModal.initial($scope, {
      $window: $window
      $q: $q
      $http: $http
      $state: $state
    })

class FeedbackCreateModal extends $unicorn.Modal
  title: _ "Create Feedback"
  slug: "feedback_create"
  single: true

  fields: ->
    [{
      slug: 'title'
      label: _("Title")
      tag: 'input'
      restrictions:
        required: true
        len: [1, 32]
    }, {
      slug: 'content'
      label: _('Content')
      tag: 'textarea'
      restrictions:
        required: true
        len: [1, 350]
    }]

  handle: ($scope, options) ->
    $http = options.$http
    $window = options.$window
    serverURL = $window.$UNICORN.settings.serverURL
    form = $scope.form
    $state = options.$state
    data =
      title: form['title']
      content: form['content']
    $http.post "#{serverURL}/feedbacks", data
      .success (feedback) ->
        $state.go 'dashboard.feedback', {}, {reload: true}
      .error (error) ->
        toastr.error _("Failed to create feedback.")
