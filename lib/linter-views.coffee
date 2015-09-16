{CompositeDisposable} = require('atom')

{BottomPanel} = require('./ui/bottom-panel')
BottomContainer = require('./ui/bottom-container')
BottomStatus = require('./ui/bottom-status')
{Message} = require('./ui/message-element')

class LinterViews
  constructor: (@linter) ->
    @state = @linter.state
    @subscriptions = new CompositeDisposable
    @messages = []
    @markers = new WeakMap()
    @panel = new BottomPanel(@state.scope)
    @bottomContainer = new BottomContainer().prepare(@linter.state)
    @bottomBar = null
    @bubble = null
    @count = File: 0, Line: 0, Project: 0

    @subscriptions.add @panel
    @subscriptions.add atom.config.observe('linter.underlineIssues', (underlineIssues) =>
      @underlineIssues = underlineIssues
    )
    @subscriptions.add atom.config.observe('linter.showErrorInline', (showBubble) =>
      @showBubble = showBubble
    )
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem =>
      @classifyMessages(@messages)
      @renderPanelMarkers({added: @messages, removed: @messages})
      @renderBubble()
      @renderCount()
      @panel.refresh(@state.scope)
    @subscriptions.add @bottomContainer.onDidChangeTab =>
      atom.config.set('linter.showErrorPanel', true)
      @panel.refresh(@state.scope)
    @subscriptions.add @bottomContainer.onShouldTogglePanel =>
      atom.config.set('linter.showErrorPanel', !atom.config.get('linter.showErrorPanel'))

  render: ({added, removed, messages}) ->
    @messages = @classifyMessages(messages)
    @panel.setMessages({added, removed})
    @renderPanelMarkers({added, removed})
    @renderBubble()
    @renderCount()

  renderLineMessages: (render = false) ->
    @classifyMessagesByLine(@messages)
    if render
      @renderCount()
      @panel.refresh(@state.scope)

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
      element = Message.fromMessage(trace)
      bubble.appendChild element
      element.updateVisibility('Project')
    bubble

  renderCount: ->
    @bottomContainer.setCount(@count)

  renderPanelMarkers: ({added, removed}) ->
    @removeMarkers(removed)
    activeEditor = atom.workspace.getActiveTextEditor()
    return unless activeEditor
    added.forEach (message) =>
      return unless message.currentFile
      @markers.set(message, marker = activeEditor.markBufferRange message.range, {invalidate: 'inside'})
      activeEditor.decorateMarker(
        marker, type: 'line-number', class: "linter-highlight #{message.class}"
      )
      activeEditor.decorateMarker(
        marker, type: 'highlight', class: "linter-highlight #{message.class}"
      ) if @underlineIssues

  attachBottom: (statusBar) ->
    @subscriptions.add atom.config.observe('linter.statusIconPosition', (statusIconPosition) =>
      @bottomBar?.destroy()
      @bottomBar = statusBar["add#{statusIconPosition}Tile"]
        item: @bottomContainer,
        priority: if statusIconPosition == 'Left' then -100 else 100
    )
    @subscriptions.add atom.config.observe('linter.displayLinterInfo', (displayLinterInfo) =>
      @bottomContainer.setVisibility(displayLinterInfo)
    )

  removeMarkers: (messages = @messages) ->
    messages.forEach((message) =>
      return unless @markers.has(message)
      marker = @markers.get(message)
      marker.destroy()
      @markers.delete(message)
    )

  removeBubble: ->
    @bubble?.destroy()
    @bubble = null

  dispose: ->
    @removeMarkers()
    @removeBubble()
    @subscriptions.dispose()
    @bottomBar?.destroy()

module.exports = LinterViews
