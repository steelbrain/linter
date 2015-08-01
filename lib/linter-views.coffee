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
    @markers = new Map()
    @panel = new BottomPanel().prepare()
    @bottomContainer = new BottomContainer().prepare(@linter.state)
    @bottomBar = null
    @bubble = null
    @count = File: 0, Line: 0, Project: 0

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
      @render(@linter.messages.publicMessages)
    @subscriptions.add @bottomContainer.onDidChangeTab =>
      @renderPanelMessages()

  render: ({added, removed, messages}) ->
    @messages = @classifyMessages(messages)
    @renderPanelMessages()
    @renderPanelMarkers({added, removed})
    @renderBubble()
    @renderCount()

  renderLineMessages: (render = false) ->
    @classifyMessagesByLine(@messages)
    if render
      @renderCount()
      @renderPanelMessages()

  classifyMessages: (messages) ->
    filePath = atom.workspace.getActiveTextEditor()?.getPath()
    @count.File = 0
    @count.Project = 0
    for key, message of messages
      if message.currentFile = (filePath and message.filePath is filePath)
        @count.File++
      @count.Project++
    return @classifyMessagesByLine(messages)

  classifyMessagesByLine: (messages) ->
    row = atom.workspace.getActiveTextEditor()?.getCursorBufferPosition().row
    @count.Line = 0
    for key, message of messages
      if message.currentLine = (message.currentFile and message.range and message.range.intersectsRow(row))
        @count.Line++
    return messages

  renderBubble: ->
    @removeBubble()
    return unless @showBubble
    activeEditor = atom.workspace.getActiveTextEditor()
    return unless activeEditor?.getPath?()
    point = activeEditor.getCursorBufferPosition()
    for message in @messages
      continue unless message.currentLine
      continue unless message.range.containsPoint point
      @bubble = activeEditor.markBufferRange([point, point], {invalidate: 'inside'})
      activeEditor.decorateMarker(@bubble,
        type: 'overlay',
        position: 'tail',
        item: @renderBubbleContent(message)
      )
      break

  renderBubbleContent: (message) ->
    bubble = document.createElement 'div'
    bubble.id = 'linter-inline'
    bubble.appendChild Message.fromMessage(message)
    if message.trace then message.trace.forEach (trace) ->
      bubble.appendChild Message.fromMessage(trace, addPath: true)
    bubble

  renderCount: ->
    @bottomContainer.setCount(@count)

  renderPanelMessages: ->
    messages = null
    if @state.scope is 'Project'
      messages = @messages
    else if @state.scope is 'File'
      messages = @messages.filter (message) -> message.currentFile
    else if @state.scope is 'Line'
      messages = @messages.filter (message) -> message.currentLine
    @panel.updateMessages messages, @state.scope is 'Project'

  renderPanelMarkers: ({added, removed}) ->
    @removeMarkers(removed)
    activeEditor = atom.workspace.getActiveTextEditor()
    return unless activeEditor
    added.forEach (message) =>
      return unless message.currentFile
      @markers.set(message.key, marker = activeEditor.markBufferRange message.range, {invalidate: 'inside'})
      activeEditor.decorateMarker(
        marker, type: 'line-number', class: "linter-highlight #{message.class}"
      )
      if @underlineIssues then activeEditor.decorateMarker(
        marker, type: 'highlight', class: "linter-highlight #{message.class}"
      )

  attachBottom: (statusBar) ->
    @bottomBar = statusBar.addLeftTile
      item: @bottomContainer,
      priority: -100

  removeMarkers: (messages = @messages) ->
    messages.forEach((message) =>
      marker = @markers.get(message.key)
      try marker.destroy()
      @markers.delete(message.key)
    )

  removeBubble: ->
    @bubble?.destroy()
    @bubble = null

  destroy: ->
    @removeMarkers()
    @removeBubble()
    @subscriptions.dispose()
    if @bottomBar
      @bottomBar.destroy()
    @panel.destroy()

module.exports = LinterViews
