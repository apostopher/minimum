###
 Copyright (C) 2012 Rahul Devaskar <apostopher@gmail.com>
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
###

# This is the minimum game's server file.
# This file defines APIs to play the game.
# It is a websocket server that listens to client requests.

###################### DEPENDENCIES ##########################
minGame  = require './minimum'
express  = require 'express'
socketio = require 'socket.io'
crypto   = require 'crypto'
##############################################################

class minServer
	###################### PRIVATE VARS ######################
	liveGames = {}
	commands =
		newGame        : 'newGame'
		makePlayerMove : 'makePlayerMove'
		hostNewGame    : 'hostNewGame'

	errors =
		newGame           : 'Error occured while starting game'
		noSuchGame        : 'No such game is in progress'
		noSuchPlayer      : 'No such player exists'
		invalidMove       : 'Invalid move'
		MinMovesRuleError : 'Not allowed to declare before minimum moves'

	createId =  (seed) ->
        shasum = crypto.createHash 'sha1'
        shasum.update seed
        shasum.digest 'base64'

    hostNewGame = (socket) ->
    	# create newGameId
    	seed = new Date
    	gameId = createId (socket.handshake.address + '@' + seed.toISOString())

    	# Notify the host about new game id
    	socket.emit 'newGameId', gameId

		# Player will share this gameId with his/her friends
		# friends would then join the game by entering gameId
		# once all friends have joined, host will start the game.
		
		true

	startNewGame = (socket, gameId, data) ->
		players = data.p
		if not players
			socket.emit 'error', error: errors.newGame
			return false

		cardsPerPlayer = (parseInt data.c, 10) || 5

		# Initiate a new Game.
		newGame = new minGame players, cardsPerPlayer

		# Save new game in memory
		liveGames[gameId] = newGame

		# Send responses to players
		for player in players
			playerState = newGame.getPlayerState player
			socket.emit (player + '@' + gameId), playerState

		return true

	makePlayerMove = (socket, gameId, player, move) ->
		# Fetch the gameState from gameId
		game = liveGames[gameId]

		# Do the validation
		if not game.gameState
			socket.emit 'error', error: errors.noSuchGame
		if not game.gameState.deal[player] # Player MUST exist.
			socket.emit 'error', error: errors.noSuchPlayer
		if not move.sc || move.if
			# Correct move attributes are not defined.
			socket.emit 'error', error: errors.invalidMove

		# All validations are OK! proceed!
		{playerState, newState} = game.makeMove player, move.sc, move.if

		# Send player states to all players
		socket.broadcast.emit ('newState@' + gameId), newState

		# Send the player's state
		socket.emit (player + '@' + gameId), playerState
		true

	declareMinimum = (socket, gameId, player) ->
		# player thinks that he has achieved minimum
		# Fetch the gameState from gameId
		game = liveGames[gameId]

		# Do the validation
		if not game.gameState
			socket.emit 'error', error: errors.noSuchGame
		if not game.gameState.deal[player] # Player MUST exist.
			socket.emit 'error', error: errors.noSuchPlayer

		# Aal izz well! proceed
		try
			gameResult = game.declareMinimum player
		catch error
			if error is errors.MinMovesRuleError
				socket.emit 'error', error: errors.MinMovesRuleError

		# Send the result to every player
		socket.broadcast.emit ('Result@' + gameId), gameResult
		socket.emit ('Result@' + gameId), gameResult

	##########################################################

	###################### PUBLIC INTERFACE ##################

	constructor: (@port) ->
		app = do express
		
		app.set 'title', 'Minimum Game'

		# Start server
		expressServer = app.listen @port
		console.log "Server listening on port #{ @port }"

		# Attach webSocket server.
		@webSocketServer = socketio.listen expressServer
		webSocketServer = @webSocketServer

		# Attach webSocket actions
		webSocketServer.sockets.on 'connection', (socket) ->
			socket.emit 'welcome', 'name': 'Minimum Game', 'commands': commands

			# Host new game event
			socket.on commands.hostNewGame, ->
				hostNewGame socket

			# Start New game event
			socket.on commands.newGame, (data) ->
				startNewGame socket, data

			# New move event
			socket.on commands.makePlayerMove, (gameId, player, move) ->
				makePlayerMove socket, gameId, player, move



# Publish module
module.exports = minServer