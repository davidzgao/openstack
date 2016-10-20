app = angular.module("Unicorn.modal", [
  "ui.router",
  "ui.bootstrap"
])

app.provider "$modalState", ($stateProvider) ->
    provider = @
    provider.$get = ->
      return provider

    provider.state = (stateName, options) ->
      modalInstance = undefined
      $stateProvider.state stateName, {
        modal: true
        url: options.url
        params: options.params
        substate: options.substate || true
        onEnter: ["$modal", "$state", ($modal, $state) ->
          if options.larger
            options.windowClass = "window-larger"
          # I don't want user to close the modal by pressing on backdrop.
          # A modal can only be closed by pressing close button created.
          options.backdrop = 'static'
          modalInstance = $modal.open(options)
          modalInstance.result.finally ->
            modalInstance = null
            if $state.$current.name == stateName
              $state.go options.successState
        ]
        onExit: ->
          if modalInstance
            modalInstance.close()
      }
    return provider
