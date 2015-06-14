BottomTabFile = require './views/bottom-tab-file'
BottomTabProject = require './views/bottom-tab-project'
BottomStatus = require './views/bottom-status'
Message = require './views/message'

class LinterViews
  constructor: (@linter) ->
    @_messages = []
    @_decorations = []
    @_showBubble = true

    @_bottomTabFile = new BottomTabFile()
    @_bottomTabProject = new BottomTabProject()
    @_panel = document.createElement 'div'
    @_bubble = document.createElement 'div'
    @_bottomStatus = new BottomStatus()

    @_bottomTabFile.initialize(@linter)
    @_bottomTabProject.initialize(@linter)
    @_bottomStatus.initialize()
    @_panelWorkspace = atom.workspace.addBottomPanel item: @_panel, visible: false

    # Set default tab to File
    @scope = 'file' # the value of @scope is changed from views/bottom-tab-{file, project}
    @_bottomTabFile.active = true
    @_panel.id = 'linter-panel'

    # Bubble
    @linter.subscriptions.add atom.config.observe 'linter.showErrorInline', (showBubble) =>
      @_showBubble = showBubble

  # This message is called in editor-linter.coffee
  render: ->
    return @_panel.hide() unless @linter.activeEditor
    return @_panel.hide() unless @linter.activeEditor.getPath?()

    counts = {project: 0, file: 0}
    activeLinter = @linter.getActiveEditorLinter()
    messages = @._extractMessages(@linter.messagesProject, counts)
    messages = messages.concat(@._extractMessages(activeLinter.messages, counts)) if activeLinter
    @_messages = messages

    @_renderPanel()
    @_bottomTabFile.count = counts.file
    @_bottomTabProject.count = counts.project
    @_bottomStatus.count = counts.project

  updateBubble: (point)->
    @removeBubble()
    return unless @_showBubble
    return unless @_messages.length
    point = point || @linter.activeEditor.getCursorBufferPosition()
    for message in @_messages
      continue unless message.currentFile
      continue unless message.range
      continue unless message.range.containsPoint point

  removeBubble: ->
    return unless @_bubble
    @_bubble.destroy()
    @_bubble = null

  # consumed in views/bottom-tab-{file, project}
  changeTab: (Tab)->
    @scope = Tab
    @_bottomTabProject.active = Tab is 'project'
    @_bottomTabFile.active = Tab is 'file'
    @_renderPanel()

  # consumed in views/panel
  setPanelVisibility: (Status)->
    if Status
      @_panelWorkspace.show() unless @_panelWorkspace.isVisible()
    else
      @_panelWorkspace.hide() if @_panelWorkspace.isVisible()

  # This method is called when we get the status-bar service
  attachBottom: (statusBar) ->
    statusBar.addLeftTile
      item: @_bottomTabFile,
      priority: -1001
    statusBar.addLeftTile
      item: @_bottomTabProject,
      priority: -1000
    statusBar.addLeftTile
      item: @_bottomStatus,
      priority: -999

  # this method is called on package deactivate
  deactivate: ->
    @_panel.removeDecorations()
    @_panelWorkspace.destroy()
    @bubble?.remove()

  _renderPanel: ->
    @_panel.innerHTML = ''
    @_removeDecorations()
    @bubble?.remove()
    if not @_messages.length
      return @setPanelVisibility(false)
    @setPanelVisibility(true)
    @_messages.forEach (message)=>
      if @scope is 'file' then return unless message.currentFile
      if message.currentFile and message.range #Add the decorations to the current TextEditor
        marker = @linter.activeEditor.markBufferRange message.range, {invalidate: 'never'}
        @_decorations.push @linter.activeEditor.decorateMarker(
          marker, type: 'line-number', class: "line-number-#{message.type.toLowerCase()}"
        )
        @_decorations.push @linter.activeEditor.decorateMarker(
          marker, type: 'highlight', class: "highlight-#{message.type.toLowerCase()}"
        )
      Element = Message.fromMessage(message, @scope is 'project')
      @_panel.appendChild Element
    @bubble?.update(@linter.activeEditor.getCursorBufferPosition())


  _removeDecorations: ->
    return unless @_decorations.length
    @_decorations.forEach (decoration) ->
      try decoration.destroy()
    @_decorations = []

  # This method is called in render, and classifies the messages according to scope
  _extractMessages: (Gen, counts) ->
    isProject = @scope is 'project'
    activeFile = @linter.activeEditor.getPath()
    ToReturn = []
    @linter.h.genValues(Gen).forEach (Entry) ->
      # Entry === Array<Messages>
      Entry.forEach (message) ->
        # If there's no file prop on message and the panel scope is file then count is as current
        if (not message.file and not isProject) or message.file is activeFile
          counts.file++
          counts.project++
          message.currentFile = true
        else
          counts.project++
          message.currentFile = false
        ToReturn.push message
    ToReturn
module.exports = LinterViews