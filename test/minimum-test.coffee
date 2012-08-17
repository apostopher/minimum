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

vows     = require 'vows'
assert   = require 'assert'
minGame  = require '../bin/minimum'
_und     = require 'underscore'

vows.describe('minimum')
    .addBatch
        'A Game':
            topic: new minGame ['Rahul', 'Vikash', 'Ankur'], 5
            'has three players': (game) ->
                assert.lengthOf _und.keys(game.gameState.deal), 3
                return
            ,
            'and one open card': (game) ->
                assert.lengthOf game.gameState.faceCards, 1
                return
    .addBatch
        'A Game with default cards':
            topic: ->
                new minGame ['Rahul', 'Vikash', 'Ankur']
            'has 5 cards per players': (game) ->
                assert.lengthOf game.gameState.deal.Rahul, 5
                return
    .export module