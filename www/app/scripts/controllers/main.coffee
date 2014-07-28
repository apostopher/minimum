'use strict'

###*
 # @ngdoc function
 # @name wwwApp.controller:MainCtrl
 # @description
 # # MainCtrl
 # Controller of the wwwApp
###
angular.module('wwwApp')
  .controller 'MainCtrl', ($scope, socketService, $state) ->
    heading_color = "#000"
    setNewColor = _.throttle () ->
      heading_color = randomColor luminosity: 'dark'
    , 1000

    $scope.getFunColor = () ->
      setNewColor()
      color: heading_color

    $scope.hostGame = (host) ->
      socketService.emit "hostGame", host.name, (error, game) ->
        $state.go 'play', {game}
