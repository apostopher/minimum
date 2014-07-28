# Copyright (C) 2014 Rahul Devaskar <apostopher@gmail.com>
"use strict"

_       = require 'lodash'
Minimum = require './minimum'
config  = require './config/config'

class GameController
  constructor: (@io) -> @games = {}

  # Private interface
  _getGameId: (prefix = "m") -> "#{prefix}#{Date.now()}#{~~(Math.random()*1e6)}"
  _getPlayersInRoom = (room) -> _.pluck @io.sockets.clients(room), 'player'

  # Public interface
  hostGame: (socket, player, sendAck) ->
    room = @_getGameId()
    socket.join room
    socket.player = player
    sendAck null, room

  joinGame: (socket, game, player, sendAck) ->
    if not @io.sockets.clients(game).length
      return sendAck config.errors.noSuchGameError

    socket.player = player
    friends = @_getPlayersInRoom game
    sendAck null, friends

    # Notify the player about successful join
    @io.sockets.in(game).emit "joinedGame:#{game}", player  
    socket.join game

  startGame: (socket, game, sendAck) ->
    players = @_getPlayersInRoom game_id
    try
      min_game = new Minimum players
    catch error
      return sendAck error

    @games[game] = min_game
    _.each @io.sockets.clients(game), (peer_socket) ->
      peer_state = min_game.getPlayerState peer_socket.player
      peer_socket.emit "#{peer_socket.player}:#{game}", peer_state

  performMove: (socket, game, player, move, sendAck) ->
    min_game = @games[game]
    if not min_game
      return sendAck config.errors.noSuchGameError
    
    if not min_game.gameState
      return sendAck config.errors.noSuchGame
    if not min_game.gameState.deal[player]
      return sendAck config.errors.noSuchPlayer
    if not (move.sc || move.if)
      return sendAck config.errors.invalidMove

    try
      player_state = game.makeMove player, move.sc, move.if
    catch error
      return sendAck config.errors[error.message]

    sendAck null, player_state
    player_state['myDeal'] = undefined
    # Send player states to all players
    @io.sockets.in(game).emit "newState:#{game}", player_state
      
  declareGame: (socket, game, player, sendAck) ->
    min_game = @games[game]

    if not min_game.gameState
      return sendAck config.errors.noSuchGame
    if not min_game.gameState.deal[player] # Player MUST exist.
      return sendAck config.errors.noSuchPlayer

    try
      game_result = game.declareMinimum player
    catch error
      return sendAck config.errors[error.message]

    @io.sockets.in(game).emit "Result:#{game}", game_result

  setupRoutes: (socket) ->
    socket.emit 'welcome', 'name': 'Minimum Game', 'commands': config.commands
    _.each config.commands, (op) => socket.on op, _.bind @[op], @, socket

module.exports = GameController