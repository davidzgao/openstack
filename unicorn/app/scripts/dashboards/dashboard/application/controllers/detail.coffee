'use strict'

angular.module("Unicorn.dashboard.application")
  .controller "dashboard.application.ApplyDetailCtr", ($scope, $http,
  $q, $window, $state, $stateParams, $dataLoader) ->
    $scope.currentId = $stateParams.applyId
    $scope.detail_tabs = [
      {
        name: _("Overview")
        url: 'dashboard.application.applyId.overview'
        available: true
      }
    ]
    applyDetail = new $unicorn.DetailView()
    applyDetail.init($scope, {
      $stateParams: $stateParams
      $state: $state
      itemId: $scope.currentId
      $dataLoader: $dataLoader
    })
  .controller 'dashboard.application.applyOverviewCtr', ($scope, $http,
  $q, $window, $state, $stateParams, $dataLoader) ->
    $scope.$emit('tabDetail', 'pending.apply.html')
    $scope.currentId = $stateParams.applyId
    (new applyDetailOverview()).init($scope, {
      $window: $window
      $http: $http
      $dataLoader: $dataLoader
    })
  .controller "dashboard.application.ErrorDetailCtr", ($scope, $http,
  $q, $window, $state, $stateParams, $dataLoader) ->
    $scope.currentId = $stateParams.errorApplyId
    $scope.detail_tabs = [
      {
        name: _("Overview")
        url: 'dashboard.application.errorApplyId.overview'
        available: true
      }
    ]
    applyDetail = new $unicorn.DetailView()
    applyDetail.init($scope, {
      $stateParams: $stateParams
      $state: $state
      itemId: $scope.currentId
      $dataLoader: $dataLoader
    })

  .controller 'dashboard.application.errorOverviewCtr', ($scope, $http,
  $q, $window, $state, $stateParams, $dataLoader) ->
    $scope.$emit('tabDetail', 'error.apply.html')
    $scope.currentId = $stateParams.errorApplyId
    (new applyDetailOverview()).init($scope, {
      $window: $window
      $http: $http
      $dataLoader: $dataLoader
    })
  .controller "dashboard.application.ReviewedDetailCtr", ($scope,
  $http, $q, $window, $state, $stateParams, $dataLoader) ->
    $scope.currentId = $stateParams.reviewedApplyId
    $scope.detail_tabs = [
      {
        name: _("Overview")
        url: 'dashboard.application.reviewedApplyId.overview'
        available: true
      }
    ]
    applyDetail = new $unicorn.DetailView()
    applyDetail.init($scope, {
      $stateParams: $stateParams
      $state: $state
      itemId: $scope.currentId
      $dataLoader: $dataLoader
    })

  .controller 'dashboard.application.reviewedOverviewCtr', ($scope,
  $http, $q, $window, $state, $stateParams, $dataLoader) ->
    $scope.$emit('tabDetail', 'reviewed.apply.html')
    $scope.currentId = $stateParams.reviewedApplyId
    (new applyDetailOverview()).init($scope, {
      $window: $window
      $http: $http
      $dataLoader: $dataLoader
    })

class applyDetailOverview
  init: ($scope, options) ->
    $window = options.$window
    $http = options.$http
    $dataLoader = options.$dataLoader

    $scope.detailItem = {
      info: _("Detail Info")
      item: {
        type: _("Apply Type")
        id: _("Id")
        create_at: _('Create At')
        project_name: _('Project Name')
        user_name: _('User Name')
      }
      apply_content: _("Apply Content")
    }

    $scope.getApply = () ->
      serverURL = $window.$UNICORN.settings.serverURL
      applyParam = "#{serverURL}/workflow-requests/#{$scope.currentId}"
      $http.get applyParam
        .success (data, status, headers) ->
          $scope.apply_detail = data
          $dataLoader $scope, $scope.apply_detail.request_type_name,
          'flat', $scope.apply_detail, true
        .error (data, status, headers) ->
          toastr.error _("Failed to get apply detail.")

    $scope.getApply()

$unicorn.applyDetailOverview = applyDetailOverview
