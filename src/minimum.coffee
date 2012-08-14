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

########################## GAME RULES #########################################
# <Game rules go here>
#
###############################################################################

######################### DEPENDANCIES ########################################
_und = require 'underscore'
###############################################################################

# This class holds the complete game.
# All the rules are stored in this class
# The state of live game is also maintained by this class
# This code will be hosted on a server machine
class minGame

    ####################### PRIVATE STATIC VARIABLES ##########################
    cardsPerDeck = 52
    jokersPerDeck = 3
    cardsPerSuite = 13
    # Total number of decks used (without jokers) 1 deck = 52 cards
    noOfDecks = 1
    # Total number of jokers to be included.
    noOfJokers = noOfDecks * jokersPerDeck

    # Total sane cards
    totalSaneCards = cardsPerDeck * noOfDecks

    # Total number of cards in deck.
    totalNoOfCards = totalSaneCards + noOfJokers

    packOfCards = [1..totalNoOfCards]
    
    # Minimum rounds after which player can declare
    minRounds = 3

    ####################### PRIVATE INTERFACE #################################

    # Get appropriate number number of cards
    getCards = (noOfPlayers, cardsPerPlayer = 5) ->
        totalCardsinHand = noOfPlayers * cardsPerPlayer
        if totalCardsinHand >= cardsPerDeck / 2
            # restOfCards is too less
            # Increase number of decks
            approxTotalCards = totalCardsinHand * 2
            totalRequiredDecks = Math.round (approxTotalCards / (cardsPerDeck + jokersPerDeck))
            totalRequiredCards = totalRequiredDecks * (cardsPerDeck + jokersPerDeck)
            return [1...totalRequiredCards]
        else
            return packOfCards

    # Returns a random card from deck of cards
    # Using Math.round() will give you a non-uniform distribution!
    getRandomCard = (cards) ->
        cardNum = Math.floor(Math.random() * (cards.length))
        randomCard = (cards.splice cardNum, 1)[0] # splice returns an array. hence [0]
        if randomCard > totalSaneCards
            randomCard = 0 # Joker card has 0 value

        # Card number 52 gives 0 with modulo. But we need 52
        randomCard = randomCard % cardsPerDeck || cardsPerDeck
        return randomCard

    # Initial deal of cards. distribute cards amoung players
    dealCards = (players, cardsPerPlayer, totalCards)->
        deal = {}                            # Initial deal is empty object
        for player in players                # Cycle through players
            if not _und.isString player      # Player name must be string
                throw 'InvalidInputError'

            for card in [0...cardsPerPlayer] # Cycle through cards per player
                if not deal[player]          # If this is the first card
                    deal[player] = []        # initiate empty array
    
                # Get random card
                randomCard = getRandomCard totalCards

                # Push the card into deal
                deal[player].push randomCard
    
        # Set the face card
        faceCard = getRandomCard totalCards
        
        # Sort everyone's deal
        for playerName, playerDeal of deal
            sortDeal playerDeal

        return 'restOfCards' : totalCards, 'deal' : deal, 'faceCards' : [faceCard], 
        'moves' : 0, 'minMoves' : (minRounds * players.length)
    
    # Check whether cards are of same type
    # Cards are same only if their modulus 13 is same.
    areEqualCards = (cards) ->
        firstCard = -1                                      # Initialization
        for card in cards                                   # Check each card
            if card <= totalSaneCards                       # Jokers are excluded
                if firstCard is -1                          # first run
                    firstCard = card % cardsPerSuite        # set first card
                else if card % cardsPerSuite isnt firstCard # if cards mismatch then
                    return false                            # return error to the caller
        return true                                         # all izz well!
    
    # Remove the cards from player's deal
    removeFromDeal = (deal, cards) ->
        for removeCard in cards               # Cycle through all cards 
            for playerCard, cardIndex in deal # Check each card in deal
                if removeCard is playerCard   # if cards match
                    deal.splice cardIndex, 1  # remove the card from deal
                    break                     # deal has unique cards so break
        return deal                           # return new deal
    

    #get the points for each card
    getPoints = (cardId) ->
        if cardId <= totalSaneCards
            # Points of card are equal to its position in suite
            # king  = 13 points
            # queen = 12 points
            # ...
            # ..
            # .
            # ace   = 1 point
            return cardId % cardsPerSuite || cardsPerSuite
        else
            # All jokers have 0 points
            return 0
    
    # get points for current deal state
    getDealPoints = (deal) ->
        totalPoints = 0                   # Initialize total points to 0
        for card in deal                  # For every card in deal
            totalPoints += getPoints card # add card points to total points
    
        return totalPoints                # return total points

    # this funtion sorts deal according to card value
    sortDeal = (deal) ->
        # This function is used as compare function in sort
        compareFn = (left, right)->
            leftPts = (getPoints left)   # left card points
            rightPts = (getPoints right) # right card points
            
            if leftPts < rightPts
                return -1
            else if leftPts > rightPts
                return 1
            else
                return 0

        deal.sort compareFn

    ####################### END OF PRIVATE INTERFACE ##########################

    ####################### PUBLIC INTERFACE ##################################
    constructor: (players, cardsPerPlayer = 5) ->
        # Save the game information
        @about =
            version : '1.0b'
            Name    : 'Minimum card game'
            authors : ['Rahul Devaskar']
            website : ''
        if not _und.isArray players
            @gameState = undefined
        try
            @gameState = dealCards players, cardsPerPlayer, getCards players.length, cardsPerPlayer
        catch error
            @gameState = error

    # Make move function
    # player will have choice to select face card OR select card from Deck.
    makeMove: (player, selectedCards, isFace) ->
        # player        : the player id for which this move is called.
        # selectedCards : Card numbers that player has selected to put.
        # faceOrDeck    : the source from which player has chosen to take card.
        
        gameState = @gameState
        # STEP 1 : Check whether selectedCards are of same type (required)
        areSame = areEqualCards selectedCards
        if not areSame
            # User is trying to cheat! STOP!
            throw 'SameCardsRuleError'
    
        # STEP 2 : take the new card
        if isFace
            # select topmost card from face cards
            newCard = do gameState.faceCards.shift
        else
            # Randomly select new card from deck cards
            newCard = getRandomCard gameState.restOfCards
    
        # STEP 3 : Add selectedCards to the faceCards
        for selectedCard in selectedCards
            # Make sure we insert interger and not string
            # "31" is incorrect
            # 31 is correct
            # as selectedCard is foreign data we can't gurantee its validity.
            # Thus we use parseInt.
            gameState.faceCards.unshift parseInt selectedCard, 10
    
        # STEP 4 : Update player's cards
        # Remove selectedCards from player's current deal
        gameState.deal.player = removeFromDeal gameState.deal[player], selectedCards
        gameState.deal.player.push newCard # add new card to player's deal
        sortDeal gameState.deal.player     # sort player's card

        # STEP 5 : if closed deck on table is empty reshuffle and set
        if gameState.restOfCards.length is 0
            topCard = do gameState.faceCards.shift
            gameState.restOfCards = faceCards
            gameState.faceCards = [topCard]

        # STEP 6 : Update total number of moves made till now
        gameState.moves += 1

        # All done. Return to caller
        return gameState

    # Player thinks he/she has minimum score
    declareMinimum: (player) ->
        gameState = @gameState
        if gameState.moves < gameState.minMoves      # check whether declaration is allowed
            throw 'MinMovesRuleError'

        deals = gameState.deal                       # get current deals
        playerWon = true                             # assume that player has won!
        gameResult = {}                              # results object
        maxScore = 0                                 # initiate max score to 0
        claimedMinimum = getDealPoints deals[player] # get claimed deal points
        delete deals[player]                         # remove user 
        for person, deal of deals                    # for each player's deal
            individualScore = getDealPoints deal     # get individual's score
            if individualScore > maxScore            # set max score to individual score
                maxScore = individualScore
            if individualScore <= claimedMinimum     # set score for winners
                individualScore = 0
                playerWon = false
            gameResult[person] = individualScore     # calculate deal points
    
        # Check whether player's has won
        if playerWon
            # Winner! set the score to 0
            gameResult[player] = 0
            return gameResult
        else
            # player lost set penalty score
            gameResult[player] =  maxScore + claimedMinimum
    
        # return result
        return gameResult

    ####################### END OF PUBLIC INTERFACE ###########################


# Publish game to window
module.exports = minGame
