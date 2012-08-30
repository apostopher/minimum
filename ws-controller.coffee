# Copyright (C) 2012 Rahul Devaskar <apostopher@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

ObjectID        = require('mongodb').ObjectID
_und            = require 'underscore'
_und.str        = require 'underscore.string'
minGame         = require './minimum'
minDbAdapter    = require './minimum.mongodb'
crypto          = require 'crypto'

# Mix underscore string functions
_und.mixin _und.str.exports()

#get database adapter object
minDb = new minDbAdapter

webSocketController = (io) ->
  # Commands available to all players
  commands =
    newGame        : 'newGame'
    joinGame       : 'joinGame'
    makePlayerMove : 'makePlayerMove'
    hostNewGame    : 'hostNewGame'
    declareGame    : 'declareGame'

  errors =
    newGame           : 'Error occured while starting game.'
    noStringPlayer    : 'Player name must be string'
    playersError      : 'invalid names of players.'
    noSuchGame        : 'No such game is in progress.'
    gameOn            : 'The game has already started.'
    noSuchPlayer      : 'No such player exists.'
    invalidMove       : 'Invalid move.'
    MinMovesRuleError : 'Not allowed to declare before minimum moves.'
    saveFailedError   : 'Saving player\'s move failed!'
    noSuchGameError   : 'No such game exists.'
    declareError      : 'Error occured in declaring game.'

  # Ids generated by this function are used to uniquely identify each game.
  createId = -> (new ObjectID()).toHexString()

  # This function is used to sanitize client-side data.
  prepareName = (name) ->
    return _und(name).chain().trim().capitalize().value()

  # Get list of player names in the room
  getPlayersInRoom = (roomid, callback) ->
    playernames = []
    playersInRoom = io.sockets.clients roomid
    playersLimit = playersInRoom.length - 1
    for playerSocket, index in playersInRoom
      playerSocket.get 'name', (err, player) ->
        playernames.push player
        if index is playersLimit
          callback playernames
    true

  # This function is called when a player wants to host new game.
  # Here hostName is the name of player who is hosting the game.
  hostNewGame = (socket, hostName) ->

    # hostname has to be string
    if not _und.isString hostName
      socket.emit 'error', error: errors.noStringPlayer
      return false

    #Sanitize host's name
    hostName = prepareName hostName

    # create newGameId
    gameId = do createId

    # Create room
    socket.join gameId

    # associate host's name to socket
    socket.set 'name', hostName, ->
      socket.set 'game', gameId, ->
        # Notify the host about new game id
        socket.emit 'newGame', {gameId, hostName}

    # Player will share this gameId with his/her friends
    # friends would then join the game by entering gameId
    # once all friends have joined, host will start the game

    true

  # join a game hosted by someone else
  joinGame = (socket, playerName, gameId) ->
    playerName = prepareName playerName
    if not gameId
      socket.emit ('error:' + gameId), error: errors.noSuchGameError
      return false

    # Check whether the game is hosted
    if not (io.sockets.clients(gameId).length)
      socket.emit ('error:' + gameId), error: errors.noSuchGameError
      return false

    # sanitize gameId
    gameId = _und(gameId).trim()

    # Check whether the game has started
    minDb.findGameById gameId, (error, game) ->
      if error is null
        # error means game has not started yet
          # associate host's name to socket
        socket.set 'name', playerName, ->
          socket.set 'game', gameId, ->
            # Send information about friends
            getPlayersInRoom gameId, (playernames) ->
              socket.emit ('friends:' + gameId), {friends: playernames, me: playerName}, (status) ->
                # Notify the player about successful join
                io.sockets.in(gameId).emit ('joinedGame:' + gameId), playerName

                # Join room
                socket.join gameId

      else
        socket.emit ('error:' + gameId), error: errors.gameOn

      true

  # This function is called when all the players are ready to start a new game.
  startNewGame = (socket, gameId) ->
    # This sub function will be called when all player names are gathered.
    startGame = (players) ->
      # Initiate a new Game.
      try
        newGame = new minGame players
      catch errObj
        console.log errObj.name + " : " + errObj.message
        return false

      # sanitize gameId
      gameId = _und(gameId).trim()

      # Save new game in Db
      minDb.saveGame gameId, newGame, (error, status) ->
        if error isnt null
          for player in players
            socket.emit ('error:' + gameId), error: errors.saveFailedError
          return false
        else
          # Send responses to players
          for playerSocket in io.sockets.clients gameId
            playerSocket.get 'name', (err, player) ->
              playerState = newGame.getPlayerState player
              if playerState
                playerSocket.emit (player + ':' + gameId), playerState
          return true
      true

    # get player names and call startGame
    getPlayersInRoom gameId, startGame

    true

  makePlayerMove = (socket, gameId, player, move) ->
    # sanitize player name
    player = prepareName player

    # sanitize gameId
    gameId = _und(gameId).trim()

    # Fetch the gameState from gameId
    minDb.findGameById gameId, (error, gameStatic) ->
      game = new minGame(null, gameStatic)
      if error
        socket.emit ('error:' + gameId), error: errors.noSuchGameError
        return false

      # Do the validation
      if not game.gameState
        socket.emit ('error:' + gameId), error: errors.noSuchGame
      if not game.gameState.deal[player] # Player MUST exist.
        socket.emit ('error:' + gameId), error: errors.noSuchPlayer
      if not (move.sc || move.if)
        # Correct move attributes are not defined.
        socket.emit ('error:' + gameId), error: errors.invalidMove

      # All validations are OK! proceed!
      playerState = game.makeMove player, move.sc, move.if

      # Save the update to database
      minDb.saveGame gameId, game, (error, updatedGame) ->
        if error
          # Update failed
          socket.broadcast.emit ('error:' + gameId), error: errors.saveFailedError
          socket.emit ('error:' + gameId), error: errors.saveFailedError
        else
          # Send the player's state
          socket.emit (player + ':' + gameId), playerState

          delete playerState['myDeal']
          # Send player states to all players
          io.sockets.in(gameId).emit ('newState:' + gameId), playerState

    true

  declareMinimum = (socket, gameId, player) ->
    # sanitize player name
    player = prepareName player

    # sanitize gameId
    gameId = _und(gameId).trim()

    # player thinks that he has achieved minimum
    # Fetch the gameState from gameId
    minDb.findGameById gameId, (error, game) ->

      # Do the validation
      if not game.gameState
        socket.emit 'error', error: errors.noSuchGame
      if not game.gameState.deal[player] # Player MUST exist.
        socket.emit 'error', error: errors.noSuchPlayer

      # Aal izz well! proceed
      try
        gameResult = game.declareMinimum player
      catch errObj
        if errObj.message is errors.MinMovesRuleError
          socket.emit 'error', error: errors.MinMovesRuleError

      # update the database
      minDb.saveGame gameId, game, (error, finishedGame) ->
        if error
          socket.emit 'error', error: errors.declareError
        else
          # Send the result to every player
          socket.broadcast.emit ('Result:' + gameId), gameResult
          socket.emit ('Result:' + gameId), gameResult
    true

  webSocketHandler = (socket) ->
    socket.emit 'welcome', 'name': 'Minimum Game', 'commands': commands

    # Host new game event
    socket.on commands.hostNewGame, (hostName)->
      hostNewGame socket, hostName

    # Join game event
    socket.on commands.joinGame, (playerName, gameId) ->
      console.log playerName
      joinGame socket, playerName, gameId

    # Start New game event
    socket.on commands.newGame, (gameId) ->
      startNewGame socket, gameId

    # New move event
    socket.on commands.makePlayerMove, (gameId, player, move) ->
      makePlayerMove socket, gameId, player, move

    # Declare game event
    socket.on commands.declareGame, (gameId, player) ->
      declareMinimum socket, gameId, player

    true

  return webSocketHandler

# Publish webSocket controller
module.exports = webSocketController
