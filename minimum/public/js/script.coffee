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

$ ->
  socket = io.connect 'http://localhost:8125'
  socket.on 'welcome', (data) -> console.log data
  socket.on 'newGame', (gameId) ->
    hostname = $('body').data 'playername'
    console.log hostname + ':' + gameId
    socket.on ('error:' + gameId), (msg) -> console.log msg
    socket.on (hostname + ':' + gameId), (msg) -> console.log msg
    socket.on ('newState:' + gameId), (msg) -> console.log msg
    socket.on ('Result:' + gameId), (msg) -> console.log msg
    socket.on ('joinedGame:' + gameId), (playername) -> console.log playername
    $('#urlholder').addClass 'alert alert-info'
    $('#urlholder').html ('http://localhost:8125/' + gameId)

  socket.on 'error', (errObj) -> console.log errObj

  ack = (status) ->
    if status is true
      console.log 'message delivered'
    else
      console.log 'message processing failed'
    true

  $('#hostGame').submit (e) ->
    hostname = $('#hostname').val()
    $('body').data 'playername', hostname
    socket.emit 'hostNewGame', hostname
    false

  $('#joinGame').submit (e) ->
    playername = $('#playername').val()
    gameid     = $('#gameid').val()
    console.log (playername + ':' + gameid)
    # attach gameId related events
    socket.on ('error:' + gameid), (msg) -> console.log msg
    socket.on (playername + ':' + gameid), (msg) -> console.log msg
    socket.on ('newState:' + gameid), (msg) -> console.log msg
    socket.on ('Result:' + gameid), (msg) -> console.log msg
    socket.on ('joinedGame:' + gameid), (playername) -> console.log playername

    socket.emit 'joinGame', playername, gameid
    false

  $('#startGame').submit (e) ->
    gameid  = $('#newgameid').val()

    # Start new game
    socket.emit 'newGame', gameid
    false


