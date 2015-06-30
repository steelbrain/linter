
{CompositeDisposable} = require('atom')

BottomPanel = require('./views/bottom-panel')
BottomContainer = require('./views/bottom-container')
BottomStatus = require('./views/bottom-status')

class LinterViews
  constructor: (@linter) ->
    @subscriptions = new CompositeDisposable
    @messages = []
    @lineMessages = []
    @markers = []
    @panel = new BottomPanel
    @bottomContainer = new BottomContainer().prepare(@linter.state)
    @bottomBar = null

    @subscriptions.add @linter.onDidClassifyMessages =>
      @render()

  render: ->
    @messages = @linter.messages.getAllMessages()
    @lineMessages = if @bottomContainer.getTab('File').attached then @linter.messages.getActiveFileMessagesForActiveRow() else []
    count = @linter.messages.getCount()
    count.Line = @lineMessages.length
    @bottomContainer.setCount(count)

  attachBottom: (statusBar) ->
    @bottomBar = statusBar.addLeftTile
      item: @bottomContainer,
      priority: -100

  destroy: ->
    @subscriptions.dispose()
    @bottomBar.destroy()

module.exports = LinterViews
