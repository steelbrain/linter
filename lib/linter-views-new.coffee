
{CompositeDisposable} = require('atom')

BottomPanel = require('./views/bottom-panel')
BottomContainer = require('./views/bottom-container')
BottomStatus = require('./views/bottom-status')

class LinterViews
  constructor: (@linter) ->
    @subscriptions = new CompositeDisposable
    @markers = []
    @panel = new BottomPanel
    @bottomContainer = new BottomContainer().prepare(@linter.state)
    @bottomBar = null

  attachBottom: (statusBar) ->
    @bottomBar = statusBar.addLeftTile
      item: @bottomContainer,
      priority: -100

  destroy: ->
    @subscriptions.dispose()
    @bottomBar.destroy()

module.exports = LinterViews
