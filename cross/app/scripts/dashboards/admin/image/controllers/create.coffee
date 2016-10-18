'use strict'

###*
 # @ngdoc function
 # @name Cross.admin.image:ImageCreateCtrl
 # @description
 # # ImageCreateCtrl
 # Controller of the Cross
###
angular.module('Cross.admin.image')
  .controller 'admin.image.ImageCreateCtr', ($scope, $imageCreate) ->
    $imageCreate($scope, true)
