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

WIDTH_CARD = 162

attachCardSelect = ->
  $('#mycards li').click (ev) ->
    $(this).toggleClass 'cardselected'
    true

attachTableCardSelect = (socket) ->
  $('#tablecards li').click (ev) ->
    me = $('body').data 'me'
    gameid = $('body').data 'gameid'
    isFace = $(this).data 'type'
    selectedCards = []
    # check whether user has selected ant cards
    for cardEle in $('#mycards li.cardselected')
      selectedCards.push parseInt ($(cardEle).attr 'id'), 10

    if selectedCards.length
      # user has selected cards
      # make move on behalf of user
      move =
        sc : selectedCards
        'if' : isFace
      socket.emit 'makePlayerMove', gameid, me, move
    true

removeselected = ->
  $('#mycards li').removeClass 'cardselected'

addPlayer = (playerName) ->
  ph3 = document.createElement 'h3'
  pcards = document.createTextNode '-'
  ph3.appendChild pcards

  ph4 = document.createElement 'h4'
  pname = document.createTextNode playerName
  ph4.appendChild pname

  pli = document.createElement 'li'
  pli.setAttribute 'id', playerName
  pli.setAttribute 'class', 'btn'
  pli.appendChild ph3
  pli.appendChild ph4

  $('#otherPlayers').append pli
  true

attachEvents = (socket, gameId, name) ->
  socket.on ('error:' + gameId), errorHandler
  socket.on (name + ':' + gameId), privateHandler
  socket.on ('newState:' + gameId), newStateHandler
  socket.on ('Result:' + gameId), resultHandler
  socket.on ('joinedGame:' + gameId), newFriendHandler
  true

errorHandler = (errObj) ->
  console.log errObj
  true

newStateHandler = (newState) ->
  # update game state
  updateGameState newState
  true

addCard = (cardnum) ->
  pli = document.createElement 'li'
  pli.setAttribute 'id', cardnum

  pimg =  document.createElement 'img'
  pimg.setAttribute 'src', "/img/#{cardnum}.png"

  pli.appendChild pimg
  $('#mycards').append pli
  true

updateMyCards = (cards) ->
  mycards = $('#mycards')
  mycards.empty()
  for card in cards
    addCard card
  totalWidth = WIDTH_CARD * cards.length
  mycards.css 'width', "#{totalWidth}"
  true

updateGameState = (state) ->
  # Update face card
  $('#opencards').html "<img src='/img/#{state.faceCards[0]}.png'/>"

  # update count of cards
  for person, cards of state.deals
    $('#' + person + ' h3').html cards

  # update next move
  $('#otherPlayers li').removeClass 'btn-primary'
  $('#' + state.nextMove).addClass 'btn-primary'

  # check whether decl button should be visible
  if state.moves >= state.minMoves
    $('#declgamediv').show()

  true

privateHandler = (state) ->
  me = $('body').data 'me'
  updateMyCards state.myDeal

  # update game state
  updateGameState state

  # Now attach cards handler
  do attachCardSelect
  true

resultHandler = (msg) ->
  console.log msg
  true

newFriendHandler = (playername) ->
  addPlayer playername
  true

# on load event
$ ->
  # Connect to websocket server
  socket = io.connect 'http://localhost:8125'

  # Attach form submit events
  # This function will be called when new game is hosted
  $('#hostGameFrm').submit (ev) ->
    hostname = $('#hostname').val()

    # attach newGameListener
    socket.on 'newGame', (gameObj) ->
      gameId = gameObj.gameId
      myName = gameObj.hostName

      # Add my name to game room
      addPlayer myName

      # add my name to page
      $('body').data 'me', myName
      $('body').data 'gameid', gameId

      $('#gameurl').html gameId
      # before showing gameid to user,
      # Add more event listeners
      attachEvents socket, gameId, myName

      $('#gameiddiv').show()
      $('#startgamediv').show()
      true

    # all set we are all ears! send host game event
    socket.emit 'hostNewGame', hostname
    false

  $('#joinGameFrm').submit (ev) ->
    joinname = $('#joinname').val()
    gameid = $('body').data 'gameid'

    # Attach listeners
    socket.on ('friends:' + gameid), (us, fn) ->

      friends = us.friends
      me = us.me

      # add my name to page
      $('body').data 'me', me

      # Add friends
      for friend in friends
        addPlayer friend

      # add me
      addPlayer me

      attachEvents socket, gameid, me
      fn true
      true

    socket.emit 'joinGame', joinname, gameid
    false

  $('#startGameFrm').submit (ev) ->
    gameid = $('body').data 'gameid'
    if gameid
      socket.emit 'newGame', gameid
    false

  $('#declGameFrm').submit (ev) ->
    gameid = $('body').data 'gameid'
    me = $('body').data 'me'
    if gameid
      socket.emit 'declareGame', gameid, me
    false

  attachTableCardSelect socket
