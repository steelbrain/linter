{CompositeDisposable} = require 'atom'

class Commands
  constructor: (@linter) ->
    @_subscriptions = new CompositeDisposable

  destroy: ->
    @_subscriptions.dispose()
module.exports = Commands