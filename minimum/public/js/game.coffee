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

attachCardSelect = ->
  $('#mycards li').click (ev) ->
    $(this).toggleClass 'cardselected'
    true

attachTableCardsSelect = ->
	$('#tablecards li').click (ev) ->
    $('#tablecards li').removeClass 'cardselected'
    $(this).addClass 'cardselected'

removeselected = ->
  $('#mycards li').removeClass 'cardselected'

$ ->
  gameId = $('body').data 'gameid'
  if gameId is ''
    #Game is not hosted
  else
    #game is hosted
    
  $('#hostGamefrm').submit (ev) ->
    hostname = $('#hostname').val()
    socket.emit 'hostNewGame', hostname
    $('#hostGameModal').modal 'hide'
    false
  # Connect to socket
  socket = io.connect 'http://localhost:8125'
  # add listners
  socket.on 'newGame', (gameId) ->
    $('body').data 'gameid', gameId
    $("#gameurl").html gameId
    do $('#gameid').show
    false

  socket.on ('friendsInRoom' + gameId), (friends) ->
    friendsHtml = '';
    for friend in friends
      friendsHtml += "<li id='#{friend}'>";
      friendsHtml += "<h3>-</h3>";
      friendsHtml += "<h4>#{friend}</h4></li>"

    $("#otherPlayers").html friendsHtml
    false

  socket.on ''
  # Get list of players who have joined this room
  do attachCardSelect
  do attachTableCardsSelect

  $('#hostGame').submit (e) ->
    hostname = $('#hostname').val()
    $('body').data 'playername', hostname
    socket.emit 'hostNewGame', hostname
    false
