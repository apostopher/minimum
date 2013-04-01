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
mongo      = require 'mongodb'
Db         = mongo.Db
Connection = mongo.Connection
Server     = mongo.Server
BSON       = mongo.BSON
ObjectID   = mongo.ObjectID

# This class will hold the interface to persistant layer (mongoDB)
class minGameDbAdapter

	constructor: (host = 'localhost', port = 27017) ->
    @db = new Db 'minGameDB', (new Server host, port, {auto_reconnect: true}), {w : 1}
  		@db.open ->
        true

  getGames: (callback) ->
    @db.collection 'games', (error, games_collection) ->
      if error
        callback error
      else
        callback null, games_collection

  getGamesCount: (callback) ->
    @db.collection 'games', (error, games_collection) ->
      if error
        callback error
      else
        games_collection.count (err, count) ->
          if err
            callback err
          else
            callback null, count
          true
      true

  findGameById: (id, callback) ->
    @getGames (error, games_collection) ->
      if error
        callback error
      else
        games_collection.findOne {_id: games_collection.db.bson_serializer.ObjectID.createFromHexString id}, (error, gameObject) ->
          if error
            callback error
          else
            callback null, gameObject

  saveGame: (gameId, gameObject, callback) ->
  	@getGames (error, games_collection) ->
  		if error
  			callback error
  		else
        gameObject._id = games_collection.db.bson_serializer.ObjectID.createFromHexString gameId
  			games_collection.save gameObject, {safe:true}, (error, status) ->
  				if error
  					callback error
  				else
  					callback null, status


module.exports = minGameDbAdapter
