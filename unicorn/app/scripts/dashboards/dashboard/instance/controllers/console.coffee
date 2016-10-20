'use strict'

angular.module('Unicorn.dashboard.instance')
  .controller 'dashboard.instance.InstanceConsoleCtr', ($scope, $http, $window,
                                         $q, $stateParams, $state, $compile) ->
    $scope.consoleUrl = ''
    currentInstance = $stateParams.instanceId
    $scope.$emit('tabDetail')

    $unicorn.serverConsole $http, $window, currentInstance, (data) ->
      if data
        $scope.consoleUrl = data.url
        $scope.tips = _("Open console in new window")
        consoleArea = angular.element('.console_area')

        detailPanel = angular.element('.detail-panel')
        consoleArea.height(detailPanel.height() - 60)
        consoleArea.width(detailPanel.width())

        vncTip = angular.element('.console_area .vnc_tip')
        vncTipContent = angular.element("<a href='#{$scope.consoleUrl}' target='blank'>#{$scope.tips}</a>")
        consoleFrame = angular.element("<iframe id='console_embed' src='#{$scope.consoleUrl}' style='width: 100%; height: 90%'></iframe>")

        vncTip.append(vncTipContent)
        if angular.element('.console_area iframe').length == 0
          consoleArea.append(consoleFrame)
