'use strict'

###*
 # @ngdoc function
 # @name admin.image.ImageCtr
 # @description
 # # ImageCtr
 # Controller of the Cross image and snapshot
###
angular.module('Cross.admin.image')
  .controller 'admin.image.ImageCtr', ($scope, $tabs) ->
    $scope.tabs = [{
      title: _('Image')
      template: 'image.tpl.html'
      enable: true
    }, {
      title: _('Snapshot')
      template: 'snapshot.tpl.html'
      enable: true
    }]

    $scope.currentTab = 'image.tpl.html'
    $tabs $scope, 'admin.image'
