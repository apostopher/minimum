'use strict'

###*
 # @ngdoc function
 # @name wwwApp.controller:PlayCtrl
 # @description
 # # PlayCtrl
 # Controller of the wwwApp
###
angular.module('wwwApp')
  .controller 'PlayCtrl', ($scope, $stateParams) ->
    $scope.game = $stateParams.game
    console.log $scope.game
