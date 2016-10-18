'use strict'

###*
 # @ngdoc overview
 # @name Cross.menu
 # @description
 # # Cross
 #
 # Main module of the application.
###

app = angular.module('Cross.menu', [])

app.run ($rootScope, $http, $window) ->
  # initial left nav bar for cross.
  return
