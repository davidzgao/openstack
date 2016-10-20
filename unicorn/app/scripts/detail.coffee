class DetailView
  detail_tabs: []

  init: ($scope, options) ->
    obj = @
    obj.$scope = $scope
    options.$this = @
    $scope.currentId = options.itemId
    $scope.$emit('detail', $scope.currentId)
    $scope.$emit('selected', $scope.currentId)

    if $scope.currentId
      $scope.detail_show = "detail_show"
      obj.detailShow($scope)
    else
      $scope.detail_show = "detail_hide"

    stateChange = false
    $scope.$on '$stateChangeSuccess', (event, toState) ->
      stateChange = true
      obj.checkActive $scope, options.$state

    $scope.$on 'tabDetail', (event) ->
      if !stateChange
        obj.checkActive $scope, options.$state

  detailShow: ($scope) ->
    container = angular.element('.datatable')
    topBar = angular.element('.unicorn-frame-main-top-tool')
    mainDiv = angular.element('.unicorn-frame-main-center')
    $scope.detailHeight = $(window).height() - container.offset().top
    if topBar.height() == 0
      $scope.detailHeight -= 36
    else
      mainDiv.css({"overflow-x": "hidden"})
    $scope.detailWidth = container.width() * 0.78

  checkActive: ($scope, $state) ->
    matched = false
    stateName = $state.current.name
    for tab in $scope.detail_tabs
      if tab.url == stateName
        tab.active = 'active'
        matched = true
      else
        tab.active = ''
    if !matched
      names = stateName.split('.')
      if names.length >= 2
        $state.go "#{names[0]}.#{names[1]}"

$unicorn.DetailView = DetailView
