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

express  = require 'express'
socketio = require 'socket.io'
stylus   = require 'stylus'
webSocketController = require './ws-controller'

app = do express
port = 8125

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
	res.render "#{__dirname}/apps/main/app",
		gameid: ''

app.get '/:id', (req, res) ->
	res.render "#{__dirname}/apps/main/app", {gameid: req.params.id}

# Start server
expressServer = app.listen app.settings.port, ->
	console.log "Server listening on port #{ app.settings.port }"

# Attach webSocket server.
@webSocketServer = socketio.listen expressServer
webSocketServer = @webSocketServer
webSocketServer.set 'log level', 1

# Attach webSocket actions
webSocketServer.sockets.on 'connection', webSocketController webSocketServer

# set meaningful title for 'ps'
process.title = 'MinServer'
