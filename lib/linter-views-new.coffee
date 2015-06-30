
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

    @subscriptions.add atom.config.observe('linter.underlineIssues', (underlineIssues) =>
      @underlineIssues = underlineIssues
    )
    @subscriptions.add atom.config.observe('linter.showErrorPanel', (showPanel) =>
      @panel.panelVisibility = showPanel
    )
    @subscriptions.add @linter.onDidClassifyMessages =>
      @render()
    @subscriptions.add @bottomContainer.onDidChangeTab =>
      @renderPanelMessages()

  render: ->
    @messages = @linter.messages.getAllMessages()
    @updateLineMessages()
    @renderPanelMessages()
    @renderPanelMarkers()

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

  renderPanelMarkers: ->
    @removeMarkers()
    activeEditor = atom.workspace.getActiveTextEditor()
    return unless activeEditor
    @messages.forEach (message) =>
      return unless message.currentFile
      @markers.push marker = activeEditor.markBufferRange message.range, {invalidate: 'never'}
      activeEditor.decorateMarker(
        marker, type: 'line-number', class: "linter-highlight #{message.class}"
      )
      if @underlineIssues then activeEditor.decorateMarker(
        marker, type: 'highlight', class: "linter-highlight #{message.class}"
      )

  updateLineMessages: (renderMessages = false) ->
    @lineMessages =
      if @bottomContainer.getTab('File').attached
        @linter.messages.getActiveFileMessagesForActiveRow()
      else []
    @renderCount()
    @renderPanelMessages() if renderMessages

  attachBottom: (statusBar) ->
    @bottomBar = statusBar.addLeftTile
      item: @bottomContainer,
      priority: -100

  removeMarkers: ->
    @markers.forEach (marker) -> try marker.destroy()
    @markers = []

  destroy: ->
    @removeMarkers()
    @subscriptions.dispose()
    @bottomBar.destroy()
    @panel.destroy()

module.exports = LinterViews
