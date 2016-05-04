app = angular.module 'battlecruisers-cards', []

app.service 'cardService', [ '$http', 'playerService', ($http, playerService)->
    cardService = {}
    cardService.deck = {}
    cardService.getDeck = () ->
        return $http.get '/static/data/cards.json'
    cardService.actions = {
        "3": {
            "main": (player_id) ->
                console.debug("Player #{player_id} is safe from main effects for this turn and next")
                playerService.addSafeTurnsToPlayer(player_id, 2)
            , "conflict": (player_id) ->
                console.debug("Player #{player_id} in conflict but nothing happens")
                null
        },
        "11": {
            "main": (player_id) ->
                console.debug("Player #{player_id} earns 4 tokens and discards a card")
                playerService.addTokensToPlayerPile(player_id,4)
                playerService.moveCardToPile(player_id, ["hand", "recovery_zone"], "discard_pile")
            , "conflict": (player_id) ->
                console.debug("Player #{player_id} is in conflict and discards a card")
                playerService.moveCardToPile(player_id, ["hand", "recovery_zone"], "discard_pile")
        },
        "13": {
            "main": (player_id) ->
                console.debug("Player #{player_id} earns 3 tokens")
                playerService.addTokensToPlayerPile(player_id, 3)
            , "conflict": (player_id) ->
                console.debug("Player #{player_id} is in conflict, so gains 3 tokens but loses 1 for each conflict")
                playerService.addTokensToPlayerPile(player_id, 3)
                playerService.addTokensToPlayerPile(player_id, -cardService.cardsInPlay.cardNumberCounts["13"])
        },
        "22": {
            "main": (player_id) ->
                console.debug("Player #{player_id} takes a token from all players, if they are not in the lead")
                console.log(playerService.whoHasMostTokens())
                console.log(player_id not in playerService.whoHasMostTokens())
                players = playerService.players
                if player_id not in playerService.whoHasMostTokens()
                    for victim_id, victim of players
                        # console.log("Conditions were almost met! #{player_id} #{victim_id}")
                        if victim_id != player_id and victim["safe_turns"] <= 0
                            # console.log("Conditions were met! #{player_id} #{victim_id}")
                            if victim["tokens"] > 0
                                playerService.addTokensToPlayerPile(victim_id, -1)
                                playerService.addTokensToPlayerPile(player_id, 1)

            , "conflict": (player_id) ->
                console.debug("Player #{player_id} is in conflict but nothing happens")
                null
        },
        "31": {
            "main": (player_id) ->
                console.debug("Player #{player_id} commands every opponent to discard a card")
                players = playerService.players
                for victim_id, victim of players
                    if victim_id is not player_id and victim["safe_turns"] <= 0
                        playerService.moveCardToPile(victim_id, "discard_pile", "hand")
            , "conflict": (player_id) ->
                console.debug("Player #{player_id} is in conflict and discards a card")
                playerService.moveCardToPile(player_id, "discard_pile", "hand")
        },
        "43": {
            "main": (player_id) ->
                playerService.addTokensToPlayerPile(player_id, 1)
                console.debug("Player #{player_id} takes 3 cards from their discard pile if they only have one card remaining")
                players = playerService.players
                if players[player_id].cards.hand.length == 1
                    playerService.moveCardToPile(player_id, "discard_pile", "hand")
            , "conflict": (player_id) ->
                console.debug("Player #{player_id} is in conflict and must discard this card (#43)")
                players = playerService.players
                for index in [players[player_id].cards.in_play.length-1...0]
                    # console.warn(index)
                    # console.warn(game.players[player_id]["cards"]["in_play"])
                    if players[player_id].cards.in_play[index].id == "43"
                        playerService.moveCardToPile(player_id, "in_play", "discard_pile", index)
                        break
        }
    }
    cardService.updateDeck = (deck) ->
        cardService.deck = deck
        return deck

    cardService.handChoice = [3, 11, 13, 22, 31, 43]
    cardService.getHand = (card_numbers=cardService.handChoice) ->
        hand = []
        for card_number in card_numbers
            card = cardService.deck[card_number]
            card["id"] = card_number
            hand.push(card)
        return {
            hand: hand,
            in_play: [],
            discard_pile: [],
            recovery_zone: [],
            active_cards: (piles = ["hand", "in_play", "recovery_zone"])->
                card_count = 0
                for pile in piles
                    card_count += this[pile].length
                return card_count
            random_card: (piles = ["hand", "in_play", "recovery_zone"]) ->
                rand = Math.floor(Math.random() * this.active_cards(piles))
                for pile in piles
                    pile_size = this[pile].length
                    if rand < pile_size
                        return {
                            card: this[pile][rand],
                            pile: pile,
                            index: rand
                        }
                    else
                        rand -= pile_size
        }

    cardService.updateCardsInPlay = (cardsInPlay) ->
        cardService.cardsInPlay = cardsInPlay

    cardService.numberOfCardsInPlay = ->
        cards_played = 0
        for card_number, count of cardService.cardsInPlay.cardNumberCounts
            cards_played += count
        return cards_played
    cardService.resetCardsInPlay = () ->
        cardService.cardsInPlay = {
            "show": false,
            "cardsPlayed": {},
            "cardNumberCounts": (new -> @[f] = 0 for f in cardService.handChoice; @)
        }

    return cardService
]


app.directive 'singleCard', ->
    {
        restrict: 'E',
        templateUrl: 'partials/single-card',
        scope: true
    }


return app
