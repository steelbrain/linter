BottomTab = require './views/bottom-tab'
BottomStatus = require './views/bottom-status'
Message = require './views/message'

class LinterViews
  constructor: (@linter) ->
    @_showBubble = true # Altered by the config observer in linter-plus
    @_messages = []
    @_markers = []
    @_statusTiles = []

    @_bottomTabFile = new BottomTab()
    @_bottomTabProject = new BottomTab()
    @_panel = document.createElement 'div'
    @_bubble = null
    @_bottomStatus = new BottomStatus()

    @_bottomTabFile.initialize("Current File", =>
      @_changeTab('file')
    )
    @_bottomTabProject.initialize("Project", =>
      @_changeTab('project')
    )
    @_bottomStatus.initialize()
    @_panelWorkspace = atom.workspace.addBottomPanel item: @_panel, visible: false

    # Set default tab to File
    @_scope = 'file'
    @_bottomTabFile.active = true
    @_panel.id = 'linter-panel'

  # Called in config observer of linter-plus.coffee
  setShowBubble: (showBubble) ->
    @_showBubble = showBubble

  # This message is called in editor-linter.coffee
  render: ->
    counts = {project: 0, file: 0}
    messages = []
    @linter.eachEditorLinter (editorLinter) =>
      messages = messages.concat @_extractMessages(editorLinter.getMessages(), counts)
    messages = messages.concat(@._extractMessages(@linter.messagesProject, counts))
    @_messages = messages

    @_renderPanel()
    @_bottomTabFile.count = counts.file
    @_bottomTabProject.count = counts.project
    @_bottomStatus.count = counts.project

  # consumed in editor-linter, _renderPanel
  updateBubble: (point) ->
    @_removeBubble()
    return unless @_showBubble
    return unless @_messages.length
    return unless @linter.activeEditor?.getPath?()
    point = point || @linter.activeEditor.getCursorBufferPosition()
    for message in @_messages
      continue unless message.currentFile
      continue unless message.range?.containsPoint? point
      @_bubble = @linter.activeEditor.decorateMarker(
        @linter.activeEditor.markBufferRange(message.range, {invalidate: 'never'}),
        {
          type: 'overlay',
          position: 'tail',
          item: @_renderBubble(message)
        }
      )
      break

  # consumed in views/panel
  setPanelVisibility: (Status) ->
    if Status
      @_panelWorkspace.show() unless @_panelWorkspace.isVisible()
    else
      @_panelWorkspace.hide() if @_panelWorkspace.isVisible()

  # This method is called when we get the status-bar service
  attachBottom: (statusBar) ->
    @_statusTiles.push statusBar.addLeftTile
      item: @_bottomTabFile,
      priority: -1001
    @_statusTiles.push statusBar.addLeftTile
      item: @_bottomTabProject,
      priority: -1000
    @_statusTiles.push statusBar.addLeftTile
      item: @_bottomStatus,
      priority: -999

  # this method is called on package deactivate
  destroy: ->
    @_removeMarkers()
    @_panelWorkspace.destroy()
    @_removeBubble()
    for statusTile in @_statusTiles
      statusTile.destroy()

  _changeTab: (Tab) ->
    @_scope = Tab
    @_bottomTabProject.active = Tab is 'project'
    @_bottomTabFile.active = Tab is 'file'
    @_renderPanel()

  _removeBubble: ->
    return unless @_bubble
    @_bubble.destroy()
    @_bubble = null

  _renderBubble: (message) ->
    bubble = document.createElement 'div'
    bubble.id = 'linter-inline'
    bubble.appendChild Message.fromMessage(message)
    if message.trace then message.trace.forEach (trace) ->
      bubble.appendChild Message.fromMessage(trace, true)
    bubble

  _renderPanel: ->
    @_panel.innerHTML = ''
    @_removeMarkers()
    @_removeBubble()
    if not @_messages.length
      return @setPanelVisibility(false)
    @setPanelVisibility(true)
    @_messages.forEach (message) =>
      if @_scope is 'file' then return unless message.currentFile
      if message.currentFile and message.range #Add the decorations to the current TextEditor
        @_markers.push marker = @linter.activeEditor.markBufferRange message.range, {invalidate: 'never'}
        @linter.activeEditor.decorateMarker(
          marker, type: 'line-number', class: "linter-highlight #{message.class}"
        )
        @linter.activeEditor.decorateMarker(
          marker, type: 'highlight', class: "linter-highlight #{message.class}"
        )
      Element = Message.fromMessage(message, @_scope is 'project')
      @_panel.appendChild Element
    @updateBubble()


  _removeMarkers: ->
    return unless @_markers.length
    for marker in @_markers
      try marker.destroy()
    @_markers = []

  # This method is called in render, and classifies the messages according to scope
  _extractMessages: (Gen, counts) ->
    isProject = @_scope is 'project'
    activeFile = @linter.activeEditor?.getPath?()
    ToReturn = []
    Gen.forEach (Entry) ->
      # Entry === Array<Messages>
      Entry.forEach (message) ->
        # If there's no file prop on message and the panel scope is file then count is as current
        if (not message.filePath and not isProject) or message.filePath is activeFile
          counts.file++
          counts.project++
          message.currentFile = true
        else
          counts.project++
          message.currentFile = false
        ToReturn.push message
    ToReturn
module.exports = LinterViews
