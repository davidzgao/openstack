'use strict'

###*
 # @ngdoc function
 # @name Cross.project.image:ImageCreateCtrl
 # @description
 # # ImageCreateCtrl
 # Controller of the Cross
###
angular.module('Cross.project.image')
  .controller 'project.image.ImageCreateCtr', ($scope, $imageCreate) ->
    $imageCreate($scope)
