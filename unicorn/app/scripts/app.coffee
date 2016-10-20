'use strict'

###*
 # @ngdoc overview
 # @name Unicorn
 # @description
 # # Unicorn
 #
 # Main module of the application.
###

loadApp = ->
  app = angular.module('Unicorn', [
      'Unicorn.dashboard',
      'Unicorn.menu',
      'Unicorn.modal',
      'Unicorn.directives',
      'Unicorn.table',
      'Unicorn.filters',
      'Unicorn.services',
      'Unicorn.login',
      'Unicorn.register',
      'Unicorn.retrieve',
      'Unicorn.reset',
      'Unicorn.main',
      'Form.builder',
      'ngAnimate',
      'ngResource',
      'ngRoute',
      'ngCookies',
      'ui.router',
      'ngSanitize',
      'ui.bootstrap',
      'ui.bootstrap-slider'
    ])

  app.config ($routeProvider, $httpProvider, $stateProvider,
              $urlRouterProvider, $modalStateProvider
              $logProvider) ->
    debug = window.$UNICORN.settings.debug
    if !debug
      debug = false
    $logProvider.debugEnabled(debug)
    $httpProvider.defaults.useXDomain = true
    $httpProvider.defaults.withCredentials = true
    $httpProvider.defaults.timeout = 5000
    delete $httpProvider.defaults.headers.common['X-Requested-With']
    $httpProvider.defaults.headers.common['X-platform'] = $UNICORN.settings.platform || 'Unicorn'
    if $UNICORN.defaultHash
      $urlRouterProvider.otherwise $UNICORN.defaultHash
    else
      $urlRouterProvider.otherwise '/login'
    $httpProvider.interceptors.push('$logincheck')
    $stateProvider
      .state 'dashboard',
        templateUrl: 'views/main.html'
        controller: 'MainCtrl'
      .state 'dashboard.userInfo',
        url: '/dashboard/userinfo/:userId'
        templateUrl: 'views/userinfo.html'
        controller: 'userInfo'
      .state 'login',
        url: '/login'
        templateUrl: 'views/login.html'
        controller: 'LoginCtrl'
      .state 'register',
        url: '/register'
        templateUrl: 'views/register.html'
        controller: 'RegisterCtrl'
      .state 'retrievepassword',
        url: '/retrievepassword'
        templateUrl: 'views/retrievepassword.html'
        controller: 'RetrieveCtrl'
      .state 'resetpassword',
        url: '/reset/:userId/:expirAt/:hash'
        templateUrl: 'views/resetpassword.html'
        controller: 'ResetCtrl'
    hCls = "class='unicorn-modal-header'"
    headerTem = "'views/common/_modal_header.html'"
    header = "<div #{hCls} ng-include src=\"#{headerTem}\"></div>"
    cCls = "class='unicorn-modal-center'"
    centerTem = "'views/common/_modal_fields.html'"
    center = "<div #{cCls} ng-include src=\"#{centerTem}\"></div>"
    $modalStateProvider
      .state "dashboard.userInfo.changePass",
        url: '/change'
        template: "#{header}#{center}"
        controller: "ModifyPassword"

    return

  if not angular.element(document).injector()
    $unicorn.removeLoading()
    angular.bootstrap document, ['Unicorn']

# Check location hash
if $unicorn.checkLocation()
  loadApp()
  return

# initial permissions
$unicorn.initialPermissions (status) ->
  if status
    loadApp()
    return
  $UNICORN.defaultHash = '/dashboard/overview'
  $unicorn.checkDash ->
    loadApp()
