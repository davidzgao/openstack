'use strict'

###*
 # @ngdoc overview
 # @name Cross
 # @description
 # # Cross
 #
 # Main module of the application.
###

loadApp = (status) ->
  modules = [
    'Cross.admin',
    'Cross.project',
    'Cross.menu',
    'Cross.modal',
    'Cross.directives',
    'Cross.table',
    'Cross.filters',
    'Cross.services',
    'Cross.login',
    'Cross.forget',
    'Cross.main',
    'Cross.user',
    'Form.builder',
    'ngAnimate',
    'ngResource',
    'ngCookies',
    'ui.router',
    'ngSanitize',
    'ui.bootstrap',
    'ui.bootstrap-slider',
    'ang-drag-drop'
  ]
  app = angular.module('Cross', modules)

  app.config ($httpProvider, $stateProvider,
              $urlRouterProvider, $modalStateProvider
              $logProvider) ->
    debug = window.$CROSS.settings.debug
    if !debug
      debug = false
    $logProvider.debugEnabled(debug)
    $httpProvider.defaults.useXDomain = true
    $httpProvider.defaults.withCredentials = true
    delete $httpProvider.defaults.headers.common['X-Requested-With']
    $httpProvider.defaults.headers.common['X-platform'] = $CROSS.settings.platform || 'Cross'
    if $CROSS.defaultHash
      $urlRouterProvider.otherwise $CROSS.defaultHash
    else
      $urlRouterProvider.otherwise '/login'
    $httpProvider.interceptors.push('$logincheck')
    $stateProvider
      .state 'admin',
        templateUrl: 'views/main.html'
        controller: 'MainCtrl'
      .state 'admin.userInfo',
        url: '/admin/userinfo/:userId'
        templateUrl: 'views/userinfo.html'
        controller: 'userInfo'
      .state 'project',
        templateUrl: 'views/main.html'
        controller: 'MainCtrl'
      .state 'login',
        abstrct: true
        templateUrl: 'views/login.html'
        controller: 'LoginCtrl'
      .state 'login.login',
        url: '/login?next'
        templateUrl: 'views/_login.html'
        controller: 'LoginCtrl'
      .state 'login.forget',
        url: '/forgetpassword'
        templateUrl: 'views/_forget.html'
        controller: 'ForgetPasswordCtrl'
      .state 'login.retirevesuccess',
        url: '/success/:action'
        templateUrl: 'views/_success.html'
        controller: 'passwordSuccessCtrl'
      .state 'login.reset',
        url: '/reset/:userId/:expirAt/:hash'
        templateUrl: 'views/_reset.html'
        controller: 'passwordResetCtrl'
    hCls = "class='cross-modal-header'"
    headerTem = "'views/common/_modal_header.html'"
    header = "<div #{hCls} ng-include src=\"#{headerTem}\"></div>"
    cCls = "class='cross-modal-center'"
    centerTem = "'views/common/_modal_fields.html'"
    center = "<div #{cCls} ng-include src=\"#{centerTem}\"></div>"
    $modalStateProvider
      .state "admin.userInfo.changePass",
        url: '/change'
        template: "#{header}#{center}"
        controller: "ModifyPassword"

    return

  if not angular.element(document).injector()
    $cross.removeLoading()
    angular.bootstrap document, ['Cross']

# Check location hash
if $cross.checkLocation()
  loadApp(401)
  return

# initial permissions
$cross.initialPermissions (status) ->
  if status
    loadApp(status)
    return
  $CROSS.defaultHash = '/admin/overview'
  $cross.sendCurrentDash ->
    loadApp()

