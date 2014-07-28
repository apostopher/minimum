'use strict'

###*
 # @ngdoc overview
 # @name wwwApp
 # @description
 # # wwwApp
 #
 # Main module of the application.
###
angular
  .module('wwwApp', [
    'ngAnimate',
    'ngCookies',
    'ngResource',
    'ngRoute',
    'ngSanitize',
    'ngTouch',
    'ui.router'
  ])
  .config ($stateProvider, $urlRouterProvider) ->
    $urlRouterProvider.otherwise "/"
    $stateProvider
      .state 'home',
        url: '/'
        templateUrl: 'views/main.html'
        controller: 'MainCtrl'

      .state 'play',
        templateUrl: 'views/play.html'
        controller: 'PlayCtrl'
        params: ['game']


