'use strict'

###*
 # @ngdoc overview
 # @name Unicorn.menu
 # @description
 # # Unicorn
 #
 # Main module of the application.
###

app = angular.module('Unicorn.menu', [])

app.run ($rootScope, $http, $window) ->
  # initial left nav bar for unicorn.
  return
