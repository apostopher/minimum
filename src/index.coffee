"use strict"

http          = require 'http'
path          = require 'path'
_             = require 'lodash'
express       = require 'express'
socketio      = require 'socket.io'
compression   = require 'compression'
redisAdapter  = require 'socket.io-redis'
bodyParser    = require 'body-parser'
config        = require './config/config'
GameCtrl      = require './gameCtrl'
{MongoClient} = require 'mongodb'

class Minimum
  constructor: ->
    @app = express()
    @server = http.createServer @app
    @io  = socketio @server
    @io.adapter redisAdapter host: 'localhost', port: 6379
    @app.use express.static path.resolve __dirname, 'www', 'dist'
    @app.use compression threshold: 512
    @app.use bodyParser.json()
    @app.use bodyParser.urlencoded extended: true

  init: (callback) ->
    MongoClient.connect "mongodb://localhost:27017/Minimum", (error, db) =>
      if error then return callback error
      @db = db
      @collection = db.collection 'games'
      @configure()
      callback null

  configure: ->
    gameCtrl = new GameCtrl @io
    @io.on 'connection', _.bind gameCtrl.setupRoutes, gameCtrl
    
  start: (callback) ->
    port = +process.argv[2] || config.port || 9090
    @server.listen port, () -> callback port

if require.main is module
  process.title = 'MinimumServer'
  server_instance = new Minimum()
  server_instance.init (error) ->
    if error then return console.log error
    server_instance.start (port) -> console.log "listening on port #{port}."