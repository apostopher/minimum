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
express  = require 'express'
socketio = require 'socket.io'
crypto   = require 'crypto'
stylus   = require 'stylus'
mongo    = require 'mongodb'
minGame  = require './minimum'
minDb    = require './minimum.mongodb'
##############################################################

class minServer
	###################### PRIVATE VARS ######################
	liveGames = {}
	commands =
		newGame        : 'newGame'
		makePlayerMove : 'makePlayerMove'
		hostNewGame    : 'hostNewGame'
		declareGame    : 'declareGame'

	errors =
		newGame           : 'Error occured while starting game'
		noSuchGame        : 'No such game is in progress'
		noSuchPlayer      : 'No such player exists'
		invalidMove       : 'Invalid move'
		MinMovesRuleError : 'Not allowed to declare before minimum moves'
		saveFailedError   : 'Saving player\'s move failed!'
		noSuchGameError   : 'No such game exists'
		declareError      : 'Error occured in declaring game'

	dbObject = null

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
			socket.emit ('error@' + gameId), error: errors.newGame
			return false

		# Initiate a new Game.
		newGame = new minGame players

		# Save new game in Db
		minDb.save gameId, newGame, (error, insertedGame) ->
			if error
				for player in players
					socket.emit ('error@' + gameId), error: errors.saveFailedError
				return false
			else
				# Send responses to players
				for player in players
					playerState = insertedGame.getPlayerState player
					socket.emit (player + '@' + gameId), playerState
				return true

		return true

	makePlayerMove = (socket, gameId, player, move) ->
		# Fetch the gameState from gameId
		minDb.findGameById gameId, (error, game) ->
			if error
				socket.emit ('error@' + gameId), error: errors.noSuchGameError
				return false

			# Do the validation
			if not game.gameState
				socket.emit ('error@' + gameId), error: errors.noSuchGame
			if not game.gameState.deal[player] # Player MUST exist.
				socket.emit ('error@' + gameId), error: errors.noSuchPlayer
			if not move.sc || move.if
				# Correct move attributes are not defined.
				socket.emit ('error@' + gameId), error: errors.invalidMove
	
			# All validations are OK! proceed!
			{playerState, newState} = game.makeMove player, move.sc, move.if
	
			# Save the update to database
			minDb.save gameId, game, (error, updatedGame) ->
				if error
					# Update failed
					socket.broadcast.emit ('error@' + gameId), error: errors.saveFailedError
					socket.emit ('error@' + gameId), error: errors.saveFailedError
				else
					# Send player states to all players
					socket.broadcast.emit ('newState@' + gameId), newState
			
					# Send the player's state
					socket.emit (player + '@' + gameId), playerState
		true

	declareMinimum = (socket, gameId, player) ->
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
			catch error
				if error is errors.MinMovesRuleError
					socket.emit 'error', error: errors.MinMovesRuleError

			# update the database
			minDb.save gameId, game, (error, finishedGame) ->
				if error
					socket.emit 'error', error: errors.declareError
				else
					# Send the result to every player
					socket.broadcast.emit ('Result@' + gameId), gameResult
					socket.emit ('Result@' + gameId), gameResult
		true

	##########################################################

	###################### PUBLIC INTERFACE ##################

	constructor: (@port) ->
		app = do express
		port = @port

		app.set 'title', 'Minimum Game'
		# Configuration
		app.configure ->
			app.use stylus.middleware
				src: __dirname + "/views"
				dest: __dirname + "/public"

			app.set 'views', __dirname + '/views'
			app.set 'view engine', 'jade'
			app.set 'port', port
			app.use express.bodyParser()
			app.use express.methodOverride()
			app.use express.cookieParser()
			app.use express.session
				secret: "KioxIqpvdyfMXOHjVkUQmGLwEAtB0SZ9cTuNgaWFJYsbzerCDn"
				#store: new RedisStore
	
			app.use require('connect-assets')()
			app.use app.router
			app.use express.static(__dirname + '/public')


		# Routes
		app.get '/', (req, res) ->
			res.render "#{__dirname}/apps/test/test"
			
		# Start server
		expressServer = app.listen app.settings.port, ->
			console.log "Server listening on port #{ app.settings.port }"

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

			# Declare game event
			socket.on commands.declareGame, (gameId, player) ->
				declareMinimum socket, gameId, player



# Publish module
module.exports = minServer