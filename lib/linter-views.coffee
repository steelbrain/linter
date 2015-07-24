{CompositeDisposable} = require('atom')

BottomPanel = require('./views/bottom-panel')
BottomContainer = require('./views/bottom-container')
BottomStatus = require('./views/bottom-status')
Message = require('./views/message')

class LinterViews
  constructor: (@linter) ->
    @state = @linter.state
    @subscriptions = new CompositeDisposable
    @messages = []
    @messagesLine = []
    @markers = []
    @panel = new BottomPanel().prepare()
    @bottomContainer = new BottomContainer().prepare(@linter.state)
    @bottomBar = null
    @bubble = null
    @renderedMessages = []


    @subscriptions.add atom.config.observe('linter.ignoredMessageTypes', (ignoredMessageTypes) =>
      @ignoredMessageTypes = ignoredMessageTypes
    )
    @subscriptions.add atom.config.observe('linter.underlineIssues', (underlineIssues) =>
      @underlineIssues = underlineIssues
    )
    @subscriptions.add atom.config.observe('linter.showErrorInline', (showBubble) =>
      @showBubble = showBubble
    )
    @subscriptions.add atom.config.observe('linter.showErrorPanel', (showPanel) =>
      @panel.panelVisibility = showPanel
    )
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem (paneItem) =>
      isTextEditor = paneItem?.getPath?
      @bottomContainer.setVisibility(isTextEditor)
      @panel.panelVisibility = atom.config.get('linter.showErrorPanel') and isTextEditor
    @subscriptions.add @linter.onDidChangeMessages =>
      @render()
    @subscriptions.add @bottomContainer.onDidChangeTab =>
      @renderPanelMessages()

  render: ->
    @messages = @linter.messages.getAllMessages()
    if @ignoredMessageTypes.length
      @messages = @messages.filter (message) => @ignoredMessageTypes.indexOf(message.type) is -1
    @updateLineMessages()
    @renderPanelMessages()
    @renderPanelMarkers()
    @renderBubble()
    @renderCount()


  renderBubble: (point) ->
    @removeBubble()
    return unless @messagesLine.length
    return unless @showBubble
    for msg in @messagesLine
      @renderedMessages.push @linter.messenger.message
        severity: msg.class
        text: msg.text
        html: msg.html
        range: msg.range
        trace: msg.trace


  renderCount: ->
    if @ignoredMessageTypes.length
      count = File: 0, Project: @messages.length
      @messages.forEach (message) -> count.File++ if message.currentFile
    else
      count = @linter.messages.getCount()
    count.Line = @messagesLine.length
    @bottomContainer.setCount(count)

  renderPanelMessages: ->
    messages = null
    if @state.scope is 'Project'
      messages = @messages
    else if @state.scope is 'File'
      messages = @messages.filter (message) -> message.currentFile
    else if @state.scope is 'Line'
      messages = @messagesLine
    @panel.updateMessages messages, @state.scope is 'Project'

  renderPanelMarkers: ->
    @removeMarkers()
    activeEditor = atom.workspace.getActiveTextEditor()
    return unless activeEditor
    @messages.forEach (message) =>
      return unless message.currentFile
      @markers.push marker = activeEditor.markBufferRange message.range, {invalidate: 'inside'}
      activeEditor.decorateMarker(
        marker, type: 'line-number', class: "linter-highlight #{message.class}"
      )
      if @underlineIssues then activeEditor.decorateMarker(
        marker, type: 'highlight', class: "linter-highlight #{message.class}"
      )

  updateLineMessages: (render = false) ->
    @messagesLine = @linter.messages.getActiveFileMessagesForActiveRow()
    if @ignoredMessageTypes.length
      @messagesLine = @messagesLine.filter (message) => @ignoredMessageTypes.indexOf(message.type) is -1
    if render
      @renderCount()
      @renderPanelMessages()

  attachBottom: (statusBar) ->
    @bottomBar = statusBar.addLeftTile
      item: @bottomContainer,
      priority: -100

  removeMarkers: ->
    @markers.forEach (marker) -> try marker.destroy()
    @markers = []

  removeBubble: ->
    # @bubble?.destroy()
    # @bubble = null
    @renderedMessages.map (msg) -> msg.destroy()

  destroy: ->
    @removeMarkers()
    @removeBubble()
    @subscriptions.dispose()
    if @bottomBar
      @bottomBar.destroy()
    @panel.destroy()

module.exports = LinterViews
