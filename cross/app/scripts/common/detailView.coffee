class DetailView
  detailDeySet: {}
  constructor: (options) ->
    @dashboard = options.dashboard
    @slug = options.slug
    @tabs = options.tabs
  messageHandle: ($scope, options) ->
    $updateDetail = options.$updateDetail
    $watchDeleted = options.$watchDeleted
    $state = options.$state
    if $updateDetail
      $updateDetail $scope
    if $watchDeleted
      $watchDeleted $scope, $state
    return true

  stateHandle: ($scope, options) ->
    $state = options.$state
    return true

  getDetail: ($scope, options) ->
    return true

  @fillScope: ($scope, obj, options) ->
    $scope.currentId = options.$stateParams["#{obj.slug}Id"]
    $selected = options.$selected
    $selected $scope
    $scope.detail_tabs = obj.tabs
    $detailShow = options.$detailShow
    $detailShow $scope
    $scope.checkActive = obj.checkActive
    $scope.checkActive $scope, obj, options
    obj.messageHandle($scope, options)
    obj.stateHandle($scope, options)
    $scope.update = () ->
      obj.getDetail()

  customScope: ($scope, options) ->
    return true

  init: ($scope, options) ->
    obj = @
    obj.$scope = $scope
    DetailView.fillScope $scope, obj, options
    @customScope($scope, options)
    @getDetail $scope, options

  checkActive: ($scope, obj, options) ->
    $state = options.$state
    detailState = "#{obj.dashboard}.#{obj.slug}.#{obj.slug}Id"
    if $state.current.name == detailState
      $state.go "#{obj.dashboard}.#{obj.slug}"
    for tab in $scope.detail_tabs
      if tab.url == $state.current.name
        tab.active = 'active'
      else
        tab.active = ''

$cross.DetailView = DetailView
