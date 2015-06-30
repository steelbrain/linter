
{CompositeDisposable} = require('atom')

BottomPanel = require('./views/bottom-panel')
BottomContainer = require('./views/bottom-container')
BottomStatus = require('./views/bottom-status')

class LinterViews
  constructor: (@linter) ->
    @state = @linter.state
    @subscriptions = new CompositeDisposable
    @messages = []
    @lineMessages = []
    @markers = []
    @panel = new BottomPanel().prepare()
    @bottomContainer = new BottomContainer().prepare(@linter.state)
    @bottomBar = null

    @subscriptions.add @linter.onDidClassifyMessages =>
      @render()

  render: ->
    @messages = @linter.messages.getAllMessages()
    @updateLineMessages()
    @renderPanelMessages()

  renderCount: ->
    count = @linter.messages.getCount()
    count.Line = @lineMessages.length
    @bottomContainer.setCount(count)

  renderPanelMessages: ->
    messages = null
    if @state.scope is 'Project'
      messages = @messages
    else if @state.scope is 'File'
      messages = @messages.filter (message) -> message.currentFile
    else if @state.scope is 'Line'
      messages = @lineMessages
    @panel.updateMessages messages, @state.scope is 'Project'

  updateLineMessages: ->
    @lineMessages =
      if @bottomContainer.getTab('File').attached
        @linter.messages.getActiveFileMessagesForActiveRow()
      else []
    @renderCount()

  attachBottom: (statusBar) ->
    @bottomBar = statusBar.addLeftTile
      item: @bottomContainer,
      priority: -100

  destroy: ->
    @subscriptions.dispose()
    @bottomBar.destroy()
    @panel.destroy()

module.exports = LinterViews
