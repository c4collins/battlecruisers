app = angular.module('battlecruisers', [])

app.controller('GameController', [ '$http', ($http) ->
    game = this

    game.cards = {}
    $http.get '/static/data/cards.json'
        .success (data) ->
            game.cards = data
    game.card_actions = {
        "3": {
            "main": (player_id) ->
                console.debug("Player #{player_id} is safe from main effects for this turn and next")
                game.addSafeTurnsToPlayer(player_id, 2)
            , "conflict": (player_id) ->
                console.debug("Player #{player_id} in conflict but nothing happens")
                null
        },
        "11": {
            "main": (player_id) ->
                console.debug("Player #{player_id} earns 4 tokens and discards a card")
                game.addTokensToPlayerPile(player_id,4)
                game.moveCardToPile(player_id, "hand", "discard_pile")
            , "conflict": (player_id) ->
                console.debug("Player #{player_id} is in conflict and discards a card")
                game.moveCardToPile(player_id, "hand", "discard_pile")
        },
        "13": {
            "main": (player_id) ->
                console.debug("Player #{player_id} earns 3 tokens")
                game.addTokensToPlayerPile(player_id, 3)
            , "conflict": (player_id) ->
                console.debug("Player #{player_id} is in conflict, so gains 3 tokens but loses 1 for each conflict")
                game.addTokensToPlayerPile(player_id, 3)
                game.addTokensToPlayerPile(player_id, -game.cardsInPlay["cardNumberCounts"]["13"])
        },
        "22": {
            "main": (player_id) ->
                console.debug("Player #{player_id} takes a token from all players, if they are not in the lead")
                console.debug(game.whoHasMostTokens())
                console.debug(player_id not in game.whoHasMostTokens())
                if player_id not in game.whoHasMostTokens()
                    for victim_id, victim of game.players
                        console.debug("Conditions were almost met! #{player_id} #{victim_id}")
                        if victim_id != player_id and victim["safe_turns"] <= 0
                            console.debug("Conditions were met! #{player_id} #{victim_id}")
                            if victim["tokens"] > 0
                                game.addTokensToPlayerPile(victim_id, -1)
                                game.addTokensToPlayerPile(player_id, 1)

            , "conflict": (player_id) ->
                console.debug("Player #{player_id} is in conflict but nothing happens")
                null
        },
        "31": {
            "main": (player_id) ->
                console.debug("Player #{player_id} commands every opponent to discard a card")
                for victim_id, victim of game.players
                    if victim_id is not player_id and victim["safe_turns"] <= 0
                        game.moveCardToPile(victim_id, "hand", "discard_pile")
            , "conflict": (player_id) ->
                console.debug("Player #{player_id} is in conflict and discards a card")
                game.moveCardToPile(player_id, "hand", "discard_pile")
        },
        "43": {
            "main": (player_id) ->
                game.addTokensToPlayerPile(player_id, 1)
                console.debug("Player #{player_id} takes 3 cards from their discard pile if they only have one card remaining")
                if game.players[player_id]["hand"].length == 1
                    game.moveCardToPile(player_id, "discard_pile", "hand")
            , "conflict": (player_id) ->
                console.debug("Player #{player_id} is in conflict and must discard this card (#43)")
                for index in [game.players[player_id]["hand"].length-1...0]
                    console.warn(index)
                    console.warn(game.players[player_id]["hand"])
                    if game.players[player_id]["in_play"][index]["id"] == "43"
                        game.moveCardToPile(player_id, "in_play", "discard_pile", index)
                        break
        }
    }

    game.getHand = (card_numbers) ->
        hand = [game.cards[card_number] for card_number in card_numbers]
        return hand[0]

    game.token_pool = 34
    game.players = {}

    game.whoHasMostTokens = () ->
        highest_tokens = 0
        player_ids = []
        console.log(game.players)
        for id, player of game.players
            if player["tokens"] > highest_tokens
                highest_tokens = player["tokens"]
                player_ids = [id]
            else if player["tokens"] == highest_tokens
                player_ids.push(id)
        return player_ids

    game.addSafeTurnsToPlayer = (player_id, num) ->
        if game.players[player_id]["safe_turns"] + num > 0
            game.players[player_id]["safe_turns"] += num
        else
            game.players[player_id]["safe_turns"] = 0
        return {player_id: game.players[player_id]}
    game.addTokensToPlayerPile = (player_id, num) ->
        if game.players[player_id]["tokens"] + num > 0
            if game.token_pool + num > 0
                game.players[player_id]["tokens"] += num
                game.token_pool -= num
            else
                game.players[player_id]["tokens"] += game.token_pool
                game.token_pool = 0
        else
            game.token_pool -= game.players[player_id]["tokens"]
            game.players[player_id]["tokens"] = 0
        return {player_id: game.players[player_id]}

    game.randomCardFromHand = (hand) ->
        return Math.floor(Math.random() * hand.length)
    game.moveCardToPile = (player_id, from_pile, to_pile, card=game.randomCardFromHand(game.players[player_id][from_pile]) ) ->
        console.debug("Player #{player_id} moves Card ##{card} from #{from_pile} to #{to_pile}" )
        game.players[player_id][to_pile].push(game.players[player_id][from_pile][card])
        return game.players[player_id][from_pile].splice(card, 1)[0]

    game.handChoice = [3, 11, 13, 22, 31, 43]
    game.newGame = (number_of_players) ->
        game.turn_number = 0
        game.over = false

        game.players = {}
        for id in [1..number_of_players]
            game.players[id] = {
                "id": id,
                "status": "NORMAL"
                "type": "ai",
                "view": "remote",
                "tokens": 0,
                "safe_turns": 0,
                "hand": game.getHand(game.handChoice)
                "in_play":[],
                "recovery_zone":[],
                "discard_pile":[]
            }
            game.players[id]
            game.addTokensToPlayerPile(id, 1)
            
            game.moveCardToPile(id, "hand", "recovery_zone")
            game.moveCardToPile(id, "hand", "discard_pile")
        
        game.buttons["new_game"]["active"] = false
        game.buttons["start_game"]["active"] = true
        console.log(game.players)

    game.reset = () ->
        game.turn_number = 0
        game.players = {}
        game.cardsInPlay = {}
        for id, button of game.buttons
            console.log(button)
            if button["id"] in ['new_game']
                button["active"] = true  
            else
                button["active"] = false    

    game.cards_in_play = []
    game.runGame = () ->
        game.buttons["start_game"]["active"] = false
        game.turn()
        game.buttons["next_turn"]["active"] = true
            

    game.turn = () ->
        if game.over
            game.buttons["next_turn"]["disabled"] = true
        else

            game.buttons["next_turn"]["disabled"] = true
            game.turn_number += 1
            game.cardsInPlay = {
                "show": false,
                "cardsPlayed": {},
                "cardNumberCounts": (new -> @[f] = 0 for f in game.handChoice; @)
            }
            # Choose a card from each player's hand
            for id, player of game.players
                if player["type"] == "ai"
                    # Handle automated players
                    cardPlayed = game.moveCardToPile(id, "hand", "in_play")
                    game.cardsInPlay["cardsPlayed"][id] = cardPlayed
                    game.cardsInPlay["cardNumberCounts"][cardPlayed["id"]] += 1
                    # console.log(cardPlayed)
                else
                    # Handle Human players
                    console.log("Removing Player " + player + " fromm game for being human")
                    game.players.splice(id, 1)
            console.log(game.cardsInPlay)

            # Reveal all cards at once
            game.cardsInPlay["show"] = true
            # Resolve Cards from lowest number to highest number
            console.log(game.cardsInPlay["cardNumberCounts"])
            for card_number, count of game.cardsInPlay["cardNumberCounts"]
                if count == 1
                    for player_id, card of game.cardsInPlay["cardsPlayed"]
                        console.debug("Player #{player_id} played card ##{card_number}")
                        # console.log(card_number)
                        # console.log(card["id"])
                        if card_number == card["id"]
                            game.card_actions[card_number]["main"](player_id)
                else if count > 1
                    for player_id, card of game.cardsInPlay["cardsPlayed"]
                        if card_number == card["id"]
                            game.card_actions[card_number]["conflict"](player_id)
            
            for id, player of game.players
                # Check for Red Alert
                total_cards = player["hand"].length + player["recovery_zone"].length
                if total_cards == 1
                    player["status"] = "RED ALERT"
                # Check for Elimination
                else if total_cards == 0
                    player["status"] = "ELIMINATED"
                else
                    player["status"] = "NORMAL"

            for id, player of game.players
                # Move cards from recovery to hand
                for index, card of player["recovery_zone"]
                    game.moveCardToPile(id, "recovery_zone", "hand", 0)
                # Move cards from play to recovery
                for index, card of player["in_play"]
                    game.moveCardToPile(id, "in_play", "recovery_zone", 0)

            for id, player of game.players
                # Check for win by tokens
                if player["tokens"] >= 15
                    player["winner"] = true
                    game.over = true
                # Check for win by attrition
                if game.players.length == 1
                    player["winner"] = true
                    game.over = true


            console.log(game.players)

            if not game.over
                game.buttons["next_turn"]["disabled"] = false
                for player in game.players
                    # Reduce all players safe tuns by 1
                    game.addSafeTurnsToPlayer(player_id, -1)
            else
                game.buttons["reset_game"]["active"] = true

                # Auto-Play
                # game.turn()





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



    return game
])

app.filter 'nonEmpty', ->
    (object) ->
        !! (object && Object.keys(object).length > 0)

return app

