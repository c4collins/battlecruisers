# (->
    app = angular.module('battlecruisers', []);

    app.controller('ButtonController', () ->
        this.buttons = [
            {
                'name': 'Start New Game',
                'text': 'Start New Game',
                'class': 'btn btn-start',
                'active': 'true',
                'action': () ->
                    console.log 'Click!'
            }
        ]
        return true
    )
    return true
# )()
