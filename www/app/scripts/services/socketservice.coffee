'use strict'

###*
 # @ngdoc service
 # @name wwwApp.socketService
 # @description
 # # socketService
 # Factory in the wwwApp.
###
angular.module('wwwApp')
  .factory 'socketService', ($rootScope) ->
    socket = io()

    # Public API here
    {
      on: (event, callback) ->
        socket.on event, ->
          args = arguments
          $rootScope.$apply ->
            callback.apply socket, args

      emit: (event, data, callback) ->
        socket.emit event, data, ->
          args = arguments
          $rootScope.$apply ->
            if callback then callback.apply socket, args
    }