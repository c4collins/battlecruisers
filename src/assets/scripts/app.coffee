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

GameController = ($http, cardService, playerService) ->
    game = this

    game.newGame = (players_array) ->
        computer_players = players_array[0]
        human_players = players_array[1]
        game.turn_number = 0
        game.over = false

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
        game.turn_number = 0
        playerService.reset()
        cardService.resetCardsInPlay()
        game.cardsInPlay = cardService.cardsInPlay
        game.cards = {}
        game.cards.actions = cardService.actions
        cardService.getDeck().success (data) ->
            game.cards.deck = data
            cardService.updateDeck(data)

        for id, button of game.buttons
            if button.id in ['new_game']
                button.active = true
            else
                button.active = false

    game.runGame = () ->
        game.buttons.start_game.active = false
        game.turn()
        game.buttons.next_turn.active = true

    game.turn = () ->
        if game.over
            game.buttons.next_turn.disabled = true
        else
            game.buttons.next_turn.disabled = true
            game.turn_number += 1

            if game.turn_number > 1
                for id, player of playerService.players
                    # Move cards from recovery to hand
                    for card in player.cards.recovery_zone
                        playerService.moveCardToPile(id, "recovery_zone", "hand", 0)
                    # Move cards from play to recovery
                    for card in player.cards.in_play
                        playerService.moveCardToPile(id, "in_play", "recovery_zone", 0)

            cardService.resetCardsInPlay()

            # Choose a card from each player's hand
            for id, player of playerService.players
                if player.status != "ELIMINATED"
                    if player.type == "ai"
                        # Handle automated players
                        random_card = player.cards.random_card(["hand"])
                        cardPlayed = playerService.moveCardToPile(id, "hand", "in_play", random_card.index)
                        cardService.cardsInPlay.cardsPlayed[id] = cardPlayed
                        cardService.cardsInPlay.cardNumberCounts[cardPlayed.id] += 1
                        cardService.updateCardsInPlay(cardService.cardsInPlay)
                    else
                        # Handle Human players
                        console.warn("Removing Player " + player.id + " from game for being human")
                        # game.players.splice(id, 1)
                else
                    console.warn("Removing Player " + player.id + " from game for being eliminated")
                    # game.players.splice(id, 1)

            # Reveal all cards at once
            cardService.cardsInPlay.show = true
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

                # else
                #     console.debug("Card ##{card_number} was not played.")

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

            for id, player of playerService.players
                # Check for win by tokens
                if player.tokens >= 15
                    player.winner = true
                    game.over = true
                # Check for win by attrition
                if playerService.players.length == 1
                    player.winner = true
                    game.over = true


            if not game.over
                game.buttons.next_turn.disabled = false
                for player in playerService.players
                    # Reduce all players safe tuns by 1
                    playerService.addSafeTurnsToPlayer(player_id, -1)
            else
                game.buttons.reset_game.active = true
                # Auto-Play
                # game.turn()
            console.log cardService.cardsInPlay

    game.buttons = {}
    $http.get '/static/data/buttons.json'
        .success (data) ->
            game.buttons = data
    game.button_actions = {
        "new_game": game.newGame,
        "start_game": game.runGame,
        "next_turn": game.turn,
        "reset_game": game.reset
    }

    game.reset()

    return game


app.controller 'GameController', [ '$http', 'cardService', 'playerService', GameController]

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
