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
