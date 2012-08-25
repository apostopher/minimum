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

minGame = require '../minimum'
should  = require('chai').should()
_und    = require 'underscore'

describe 'Minimum Game', ->
  describe 'when creating a new game with 6 players', ->
    myGame = null
    before ->
        myGame = new minGame ["Rahul", "Brajesh", "Vikash", "Ram", "Ankur", "Nikit"]

    it 'should create initial game state', ->
        myGame.gameState.should.exist

    it 'should have 6 players', ->
        _und.keys(myGame.gameState.deal).should.have.length 6

    it 'and each player should have 5 cards', ->
        _und.each _und.keys(myGame.gameState.deal), (key) ->
            myGame.gameState.deal[key].should.have.length 5

    it 'should use only one deck', ->
        myGame.gameState.noOfDecks.should.equal 1

    it 'and each player should have unique cards except for jokers', ->
        _und.each _und.keys(myGame.gameState.deal), (key) ->
            cardsWithoutJokers = _und.compact myGame.gameState.deal[key]
            cardsWithoutJokers.should.have.length (_und.uniq cardsWithoutJokers).length

    it 'should have only one face card', ->
        myGame.gameState.faceCards.should.have.length 1

    it 'should have appropriate number of closed cards', ->
        totalCardsinUse = 6*5 + 1
        myGame.gameState.restOfCards.should.have.length (56 - totalCardsinUse)

  describe 'when creating a new game with 9 players', ->
    myGame = null
    before ->
        myGame = new minGame ["Rahul", "Brajesh", "Vikash", "Ram", "Ankur", "Nikit", "Parth", "Shailesh", "Tushar"]

    it 'should use two decks', ->
        myGame.gameState.noOfDecks.should.equal 2

  describe 'when player makes a move by selecting face card', ->
    myGame    = null
    myCards   = null
    faceCards = null
    before ->
        myGame = new minGame ["Rahul", "Brajesh", "Vikash", "Ram", "Ankur", "Nikit"]
        myCards = _und.union myGame.gameState.deal["Rahul"], []
        faceCards = _und.union myGame.gameState.faceCards, []
        myGame.makeMove "Rahul", [myGame.gameState.deal["Rahul"][4]], true

    it 'should have one card added to top of faceCards', ->
        myGame.gameState.faceCards.should.have.length faceCards.length
        myGame.gameState.faceCards[0].should.equal myCards[4]

    it 'should have face card in his hand', ->
        found = _und.find myGame.gameState.deal["Rahul"], (card) -> card is faceCards[0]
        found.should.not.be.undefined

  describe 'when player makes a move by selecting close card', ->
    myGame    = null
    myCards   = null
    faceCards = null
    before ->
        myGame = new minGame ["Rahul", "Brajesh", "Vikash", "Ram", "Ankur", "Nikit"]
        myCards = _und.union myGame.gameState.deal["Rahul"], []
        faceCards = _und.union myGame.gameState.faceCards, []
        myGame.makeMove "Rahul", [myGame.gameState.deal["Rahul"][4]], false

    it 'should have one card added to top of faceCards', ->
        myGame.gameState.faceCards.should.have.length (faceCards.length + 1)
        myGame.gameState.faceCards[0].should.equal myCards[4]


  describe 'when all closed cards are utilized', ->
    myGame = null
    before ->
        myGame = new minGame ["Rahul", "Brajesh", "Vikash", "Ram", "Ankur", "Nikit"]
        restOfCards = myGame.gameState.restOfCards.length
        pending = true
        while pending
          for player in _und.keys myGame.gameState.deal
              if myGame.gameState.moves is restOfCards
                  pending = false
                  break
              myGame.makeMove player, [myGame.gameState.deal[player][4]], false


    it 'should put topmost face card aside', ->
        myGame.gameState.faceCards.should.have.length 1

