tabApp = angular.module("Unicorn.tab", [])

tabApp.directive 'tab', () ->
  return {
    restrict: 'A'
    transclude: true
    scope: {
      'tab': '='
    }
    templateUrl: '../views/tab/sampleTab.html'
    link: (scope, ele, attr) ->
      scope.tabs = scope.tab
  }
