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

    ####################### PRIVATE STATIC CONSTANTS ##########################
    CARDS_PER_DECK   = 52
    JOKERS_PER_DECK  = 4
    CARDS_PER_SUITE  = 13
    CARDS_PER_PLAYER = 5
    JOKER_CARD       = 0 # identifier for joker card also equal to its points
    MIN_ROUNDS       = 3 # Minimum rounds after which player can declare

    # Game states
    RUNNING  = 1
    FINISHED = 2

    ####################### PRIVATE INTERFACE #################################

    #get appropriate number of jokers
    getJokers = (numOfJokers) ->
      jokers = []
      for num in [0...numOfJokers]
        jokers.push JOKER_CARD
      return jokers

    # Get appropriate number of cards
    getCards = (noOfPlayers) ->
        totalCardsinHand = noOfPlayers * CARDS_PER_PLAYER
        if totalCardsinHand >= CARDS_PER_DECK / 2
            # restOfCards is too less
            # Increase number of decks
            approxTotalCards = totalCardsinHand * 2

            # set static variables to new values
            # Total number of decks used (without jokers) 1 deck = 52 cards
            noOfDecks = Math.round (approxTotalCards / (CARDS_PER_DECK + JOKERS_PER_DECK))

            # Total number of jokers to be included.
            noOfJokers = noOfDecks * JOKERS_PER_DECK

            # Total sane cards
            totalSaneCards = noOfDecks * CARDS_PER_DECK

            # Total number of cards.
            packOfCards = ([1..totalSaneCards]).concat getJokers noOfJokers
        else
            packOfCards = ([1..CARDS_PER_DECK]).concat getJokers JOKERS_PER_DECK
            noOfDecks = 1

        returnValue =
            'packOfCards' : (_und.shuffle packOfCards)
            'noOfDecks'   : noOfDecks
        return returnValue

    # Returns a card from deck of cards
    # this function will map any card number to appropriate card in 52 cards.
    # e.g. this would convert 112 to appropriate card within 52
    getCard = (cards) ->
        if cards.length
            randomCard = do cards.shift
            if randomCard is JOKER_CARD
                return JOKER_CARD # Joker card has 0 value

            # Card number 52 gives 0 with modulo. But we need 52
            randomCard = randomCard % CARDS_PER_DECK || CARDS_PER_DECK
            return randomCard
        else
            # nothing to select
            return undefined

    # Initial deal of cards. distribute cards amoung players
    dealCards = (players, totalCards)->
        deal = {}                            # Initial deal is empty object
        totalCardsLen  = totalCards.length
        totalJokers    = totalCardsLen % CARDS_PER_DECK
        totalSaneCards =  totalCardsLen - totalJokers
        for player in players                # Cycle through players
            if not _und.isString player      # Player name must be string
                throw new TypeError 'InvalidInputError'

            for card in [0...CARDS_PER_PLAYER] # Cycle through cards per player
                if not deal[player]          # If this is the first card
                    deal[player] = []        # initiate empty array

                # Get random card
                randomCard = getCard totalCards, totalSaneCards

                # Push the card into deal
                deal[player].push randomCard

        # Set the face card
        faceCard = getCard totalCards, totalSaneCards

        # Sort everyone's deal
        for playerName, playerDeal of deal
            sortDeal playerDeal

        return 'restOfCards' : totalCards, 'deal' : deal, 'faceCards' : [faceCard],
        'moves' : 0, 'minMoves' : (MIN_ROUNDS * players.length), 'players' : players,
        'nextMove' : 0

    # Check whether cards are of same type
    # Cards are same only if their modulus 13 is same.
    areEqualCards = (cards) ->
        firstCard = -1                                      # Initialization
        for card in cards                                   # Check each card
            if card isnt JOKER_CARD                         # Jokers are excluded
                if firstCard is -1                          # first run
                    firstCard = card % CARDS_PER_SUITE        # set first card
                else if card % CARDS_PER_SUITE isnt firstCard # if cards mismatch then
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
        if cardId isnt JOKER_CARD
            # Points of card are equal to its position in suite
            # king  = 13 points
            # queen = 12 points
            # ...
            # ..
            # .
            # ace   = 1 point
            return cardId % CARDS_PER_SUITE || CARDS_PER_SUITE
        else
            # All jokers have 0 points
            return JOKER_CARD

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
    constructor: (players, me) ->
        if me
            # this is a copy constructor
            @gameState = me.gameState
        else
            if not _und.isArray players  # players must be array of strings
                throw new TypeError 'InvalidPlayersError'

            # Get required number of cards
            {packOfCards, noOfDecks} = getCards players.length
            # Get initial deal
            @gameState = dealCards players, packOfCards
            # set number of decks in use
            @gameState.noOfDecks = noOfDecks
            # set the game state to RUNNING
            @gameState.currentState = RUNNING

    # Get player's state
    # This is a subset of complete game state
    # Player's state consists of this hand cards, and face card only
    getPlayerState: (player) ->
        gameState = @gameState
        # This state will be sent to player
        playerState =
            faceCards : gameState.faceCards # player will get faceCards
            moves     : gameState.moves     # number of moves till this time
            nextMove  : gameState.players[gameState.nextMove]  # who will play next?
            minMoves  : gameState.minMoves  # minimum moves to declare

        # Add deal information
        playerState.deals = {}

        for gamePlayer, gamePlayerDeal of gameState.deal
            # player will ge count of other player's cards
            playerState.deals[gamePlayer] = gamePlayerDeal.length
            if gamePlayer is player
                playerState['myDeal'] = gamePlayerDeal

        return playerState

    # Make move function
    # player will have choice to select face card OR select card from Deck.
    makeMove: (player, selectedCards, isFace) ->
        # player        : the player id for which this move is called.
        # selectedCards : Card numbers that player has selected to put.
        # faceOrDeck    : the source from which player has chosen to take card.

        gameState = @gameState

        # STEP 1 : Check the state of game
        if gameState.currentState is FINISHED
          # This game is over
          throw new Error 'GameOverError'

        # STEP 2 : Check whether player is allowed to make move
        if player isnt gameState.players[gameState.nextMove]
          # this player is not allowed to make move
          err = new Error 'NotAllowedToMakeMoveError'
          throw err

        # STEP 3 : Check whether selectedCards are of same type (required)
        if selectedCards.length is 1
            # if only one card it has to same :-)
            areSame = true
        else
            # more than one card. Check whether all are same.
            areSame = areEqualCards selectedCards

        if not areSame
            # User is trying to cheat! STOP!
            throw new Error 'SameCardsRuleError'

        # STEP 4 : take the new card
        if isFace
            # select topmost card from face cards
            newCard = getCard gameState.faceCards
        else
            # Randomly select new card from deck cards
            newCard = getCard gameState.restOfCards

        # STEP 5 : Add selectedCards to the faceCards
        for selectedCard in selectedCards
            # Make sure we insert interger and not string
            # "31" is incorrect
            # 31 is correct
            # as selectedCard is foreign data we can't gurantee its validity.
            # Thus we use parseInt.
            gameState.faceCards.unshift parseInt selectedCard, 10

        # STEP 6 : Update player's cards
        # Remove selectedCards from player's current deal
        gameState.deal[player] = removeFromDeal gameState.deal[player], selectedCards
        gameState.deal[player].push newCard # add new card to player's deal
        sortDeal gameState.deal[player]     # sort player's card

        # STEP 7 : if closed deck on table is empty reshuffle and set
        if gameState.restOfCards.length is 0
            topCard = do gameState.faceCards.shift
            # shuffle face cards and keep them as restOfCards
            gameState.restOfCards = _und.shuffle gameState.faceCards
            # reset facecards to only one card.
            gameState.faceCards = [topCard]

        # STEP 8 : Update total number of moves made till now
        gameState.moves += 1

        # STEP 9 : update who will play next
        gameState.nextMove += 1
        if gameState.nextMove is gameState.players.length
            gameState.nextMove = 0

        # All done. Return player's state to caller
        return @getPlayerState player

    # Player thinks he/she has minimum score
    declareMinimum: (player) ->
        gameState = @gameState

        # check the state of game
        if gameState.currentState is FINISHED
          # This game is over
          throw new Error 'GameOverError'

        if player isnt gameState.players[gameState.nextMove]
          # this player is not allowed to make move
          err = new Error 'NotAllowedToMakeMoveError'
          throw err

        if gameState.moves < gameState.minMoves      # check whether declaration is allowed
            throw new Error 'MinMovesRuleError'

        deals = gameState.deal                       # get current deals
        playerWon = true                             # assume that player has won!
        gameState.result = {}                        # results object
        gameState.winners = []                       # initiate winner's array
        maxScore = 0                                 # initiate max score to 0
        claimedMinimum = getDealPoints deals[player] # get claimed deal points
        for person, deal of deals                    # for each player's deal
            if person isnt player                    # for all other players
                individualScore = getDealPoints deal # get individual's score
                if individualScore > maxScore        # set max score to individual score
                    maxScore = individualScore
                if individualScore <= claimedMinimum # set score for winners
                    individualScore = 0
                    playerWon = false
                    gameState['winners'].push person
                gameState.result[person] = individualScore # calculate deal points

        # Check whether player's has won
        if playerWon
            # Winner! set the score to 0
            gameState.result[player] = 0
            gameState['winners'].push player
        else
            # player lost set penalty score
            gameState.result[player] =  maxScore + claimedMinimum

        # delete next move attribute
        delete gameState['nextMove']

        # add who declare info
        gameState['whoDeclared'] = player

        # set game state to FINISHED
        gameState.currentState = FINISHED

        # return result
        return gameState

    ####################### END OF PUBLIC INTERFACE ###########################


# Finally Publish game
module.exports = minGame
