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
    @markers = []
    @panel = new BottomPanel().prepare()
    @bottomContainer = new BottomContainer().prepare(@linter.state)
    @bottomBar = null
    @bubble = null
    @renderedMessages = []
    @count = File: 0, Line: 0, Project: 0

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
      @render(@linter.messages.publicMessages)
    @subscriptions.add @bottomContainer.onDidChangeTab =>
      @renderPanelMessages()

  render: (messages) ->
    @messages = @classifyMessages(messages)
    if @ignoredMessageTypes.length
      @messages = @messages.filter (message) => @ignoredMessageTypes.indexOf(message.type) is -1
    @renderPanelMessages()
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
    prepared = []
    for msg in @messages
      continue unless msg.currentFile
      prepared.push {
          severity: msg.class
          text: msg.text
          html: msg.html
          range: msg.range
          trace: msg.trace
          suggestion: msg.suggestion
      }
    @renderedMessages = @linter.messenger.manyMessages prepared

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
 
  attachBottom: (statusBar) ->
    @bottomBar = statusBar.addLeftTile
      item: @bottomContainer,
      priority: -100

  removeBubble: ->
    @renderedMessages.map (msg) -> msg.destroy()

  destroy: ->
    @removeMarkers()
    @removeBubble()
    @subscriptions.dispose()
    if @bottomBar
      @bottomBar.destroy()
    @panel.destroy()

module.exports = LinterViews
