app = angular.module('battlecruisers', ['ngRoute', 'battlecruisers-players', 'battlecruisers-cards'])

app.config ($routeProvider, $locationProvider) ->
    $locationProvider.html5Mode true
    $routeProvider.when '/', {
        templateUrl: 'index.html',
        controller: 'GameController',
        controllerAs: 'game'
    }
    .when '/partials/:name', {
        templateUrl: 'partials/:name'
        }
    .otherwise {
        redirectTo: '/'
    }

GameController = ($http, $timeout, cardService, playerService) ->
    game = this
    game.phase = 0
    ## Game Phases
    # 0 - Pre-Game / Game-Over
    # 1 - Game Started
    # 2 - Game Waiting for Player to play card

    game.newGame = (players_array) ->
        computer_players = players_array[0]
        human_players = players_array[1]
        game.turn_number = 0
        game.over = false
        game.phase = 1

        for id in [1..human_players]
            player = playerService.createNewPlayer(id, 'human')
            player.cards = cardService.getHand()
            playerService.updatePlayer(id, player)
            console.log(player)
        for id in [1+human_players..computer_players+human_players]
            player = playerService.createNewPlayer(id, 'ai')
            player.cards = cardService.getHand()
            playerService.updatePlayer(id, player)

        for id, player of playerService.players
            playerService.addTokensToPlayerPile(id, 1)

            playerService.moveCardToPile(id, "hand", "recovery_zone")
            playerService.moveCardToPile(id, "hand", "discard_pile")

        game.buttons.new_game.active = false
        game.buttons.start_game.active = true

    game.reset = () ->
        console.warn 'RESETTING GAME!'
        # Game functions
        game.turn_number = 0
        game.phase = 0
        # Player functions
        playerService.reset()
        # Card functions
        cardService.resetCardsInPlay()
        game.cardsInPlay = cardService.cardsInPlay
        game.cards = {}
        game.cards.actions = cardService.actions
        cardService.getDeck().success (data) ->
            game.cards.deck = data
            cardService.updateDeck(data)
        # Button functions
        for id, button of game.buttons
            if button.id in ['new_game']
                button.active = true
            else
                button.active = false

    game.runGame = () ->
        game.buttons.start_game.active = false
        game.turn_fn()
        game.buttons.next_turn.active = true


    game.turn = {}
    game.turn.processCardActions = ->
        # Resolve Cards from lowest number to highest number
        for card_number, count of cardService.cardsInPlay.cardNumberCounts
            if count > 0
                # game.players = playerService.players
                if count == 1
                    for player_id, card of cardService.cardsInPlay.cardsPlayed
                        if card_number == card.id.toString()
                            console.debug("Player #{player_id} played card ##{card.id}")
                            game.cards.actions[card_number].main(player_id)
                else
                    for player_id, card of cardService.cardsInPlay.cardsPlayed
                        if card_number == card.id.toString()
                            console.debug("Player #{player_id} played card ##{card.id}")
                            game.cards.actions[card_number].conflict(player_id)

    game.turn.rotateCardStacks = ->
        if game.turn_number > 1
            for id, player of playerService.players
                # Move cards from recovery to hand
                for card in player.cards.recovery_zone
                    playerService.moveCardToPile(id, "recovery_zone", "hand", 0)
                # Move cards from play to recovery
                for card in player.cards.in_play
                    playerService.moveCardToPile(id, "in_play", "recovery_zone", 0)
        cardService.resetCardsInPlay()

    game.turn.playAIHands = ->
        for player_id, player of playerService.players
            if player.status != "ELIMINATED" and player.type == 0
                if player.difficulty == 0
                    random_card = player.cards.random_card(["hand"])
                    cardPlayed = playerService.moveCardToPile(player_id, "hand", "in_play", random_card.index)
                    cardService.cardsInPlay.cardsPlayed[player_id] = cardPlayed
                    cardService.cardsInPlay.cardNumberCounts[cardPlayed.id] += 1
                    cardService.updateCardsInPlay(cardService.cardsInPlay)
                else
                    console.error("No or invalid AI difficulty set.", player, player.difficulty, player.difficulty == 0)

    game.turn.checkForElimination = ->
        for id, player of playerService.players
            total_cards = player.cards.hand.length + player.cards.recovery_zone.length
            # Check for Elimination
            if total_cards == 0
                player.status = "ELIMINATED"
            # Check for Red Alert
            else if total_cards == 1
                player.status = "RED ALERT"
            else
                player.status = "NORMAL"

    game.turn.checkForEndOfGame = ->
        for id, player of playerService.players
            # Check for win by tokens
            if player.tokens >= 15
                player.winner = true
                game.over = true
            # Check for win by attrition
            if playerService.players.length == 1
                player.winner = true
                game.over = true

    game.turn.processEndOfTurn = ->
        if not game.over
            for player in playerService.players
                # Reduce all players safe turns by 1
                playerService.addSafeTurnsToPlayer(player_id, -1)
            game.buttons.next_turn.disabled = false
        else
            game.buttons.reset_game.active = true

    game.turn_fn = () ->
        if game.over
            game.buttons.next_turn.disabled = true
        else
            game.buttons.next_turn.disabled = true
            game.turn_number += 1

            game.turn.rotateCardStacks()
            game.turn.playAIHands()
            cardService.cardsInPlay.show = true

            game.turn.waitForPlayer = ->
                if cardService.numberOfCardsInPlay() == playerService.numberOfPlayers
                    game.phase = 1
                    console.log "Correct number of player cards found!"
                    game.turn.processCardActions()
                    game.turn.checkForElimination()
                    game.turn.checkForEndOfGame()
                    game.turn.processEndOfTurn()
                else
                    game.phase = 2
                    console.log "Waiting for player input"
                    console.log cardService.numberOfCardsInPlay(), playerService.numberOfPlayers, cardService.numberOfCardsInPlay() == playerService.numberOfPlayers
                    $timeout(game.turn.waitForPlayer, 1000)
            game.turn.waitForPlayer()

    game.userCardClick = (player_id, card_index, pile, action) ->
        console.log "Game Phase: #{game.phase}"
        if action == 'play_card' and game.phase == 2
            cardPlayed = playerService.moveCardToPile(player_id, pile, "in_play", card_index)
            cardService.cardsInPlay.cardsPlayed[player_id] = cardPlayed
            cardService.cardsInPlay.cardNumberCounts[cardPlayed.id] += 1
            cardService.updateCardsInPlay(cardService.cardsInPlay)

    game.buttons = {}
    $http.get '/static/data/buttons.json'
        .success (data) ->
            game.buttons = data
    game.button_actions = {
        "new_game": game.newGame,
        "start_game": game.runGame,
        "next_turn": game.turn_fn,
        "reset_game": game.reset
    }

    game.reset()

    return game


app.controller 'GameController', [ '$http', '$timeout', 'cardService', 'playerService', GameController]

app.directive 'playArea', ['cardService', (cardService) ->
    {
        restrict: 'E',
        templateUrl: 'partials/play-area',
        link: (scope, el, attrs) ->
            scope.cardService = cardService
    }
]
app.directive 'gameHeader', ->
    {
        restrict: 'E',
        templateUrl: 'partials/game-header',
        scope: true
    }
app.directive 'gameControlButtons', ->
    {
        restrict: 'E',
        templateUrl: 'partials/game-control-buttons',
        scope: true
    }

return app
