app = angular.module 'battlecruisers-players', []

app.directive 'playerInfo', ['playerService', (playerService) ->
    {
        restrict: 'E',
        templateUrl: 'partials/player-info',
        link: (scope, el, attrs) ->
            scope.playerService = playerService
    }
]

app.service 'playerService', [ ()->
    playerService = {}
    playerService.players = {}
    playerService.token_pool = 34

    playerService.createNewPlayer = (id, type) ->
      player = {
          "id": id,
          "status": "NORMAL"
          "type": type,
          "view": "remote",
          "tokens": 0,
          "safe_turns": 0
      }
      playerService.updatePlayer(id, player)
      return player

    playerService.updatePlayer = (id, player) ->
        playerService.players[id] = player
        return player

    playerService.reset = () ->
        playerService.players = {}
        playerService.token_pool = 34

    playerService.whoHasMostTokens = () ->
        highest_tokens = 0
        player_ids = []
        for id, player of playerService.players
            if player.tokens > highest_tokens
                highest_tokens = player.tokens
                player_ids = [id]
            else if player.tokens == highest_tokens
                player_ids.push(id)
        return player_ids

    playerService.addSafeTurnsToPlayer = (player_id, num) ->
        player = playerService.players[player_id]
        if player.safe_turns + num > 0
            player.safe_turns += num
        else
            player.safe_turns = 0
        return {player_id: player}

    playerService.addTokensToPlayerPile = (player_id, num) ->
        player = playerService.players[player_id]
        if player.tokens + num > 0
            if playerService.token_pool + num > 0
                player.tokens += num
                playerService.token_pool -= num
            else
                player.tokens += playerService.token_pool
                playerService.token_pool = 0
        else
            playerService.token_pool -= player.tokens
            player.tokens = 0
        return {player_id: playerService.players[player_id]}

    playerService.randomCardFromHand = (pile) ->
        # // TODO pile can be an array of piles... this function already exists in the player.cards object and this may be completely unnecessary
        return Math.floor(Math.random() * pile.length)

    playerService.moveCardToPile = (player_id, from_pile, to_pile, card) ->
        if typeof from_pile == "string"
            from_pile = [from_pile]
        if card == undefined
            card = playerService.players[player_id].cards.random_card(from_pile).index
        console.debug("Player #{player_id} moves Card ##{card} from #{from_pile} to #{to_pile}" )
        player = playerService.players[player_id]
        if player.cards[from_pile][card] != undefined
            player.cards[to_pile].push(player.cards[from_pile][card])
        else
            throw new Error("That card (#{card}) is undefined! From: #{from_pile} To: #{to_pile} For Player #{player_id}")
        return player.cards[from_pile].splice(card, 1)[0]

    return playerService
]
