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
	commands =
		newGame : 'new game'

	errors =
		newGame : 'Error occured while starting game'

	createId =  (seed) ->
        shasum = crypto.createHash 'sha1'
        shasum.update seed
        shasum.digest 'base64'

	startNewGame = (data) ->
		players = data.p
		if not players
			socket.emit 'game created', error: errors.newGame
			return false

		cardsPerPlayer = (parseInt data.c, 10) || 5

		# Initiate a new Game.
		newGame = new minGame players, cardsPerPlayer
		seed = new Date
		gameId = createId (socket.handshake.address + '@' + seed.toISOString())
		socket.emit 'game created', id: gameId
		return true

	##########################################################

	###################### PUBLIC INTERFACE ##################

	constructor: (@port) ->
		@expressServer = do express
		expressServer = @expressServer

		expressServer.set 'title', 'Minimum Game'

		# Attach webSocket server.
		@webSocketServer = socketio.listen expressServer
		webSocketServer = @webSocketServer

		# Attach webSocket actions
		io.sockets.on 'connection', (socket) ->
			socket.emit 'welcome', 'name': 'Minimum Game', 'commands': commands

			# New game event
			socket.on commands.newGame, startNewGame

  
		# Start server
		expressServer.listen @port