BottomTab = require './views/bottom-tab'
BottomStatus = require './views/bottom-status'
Message = require './views/message'

class LinterViews
  constructor: (@linter) ->
    @showPanel = true # Altered by config observer in linter-plus
    @showBubble = true # Altered by the config observer in linter-plus
    @underlineIssues = true # Altered by config observer in linter-plus

    @messages = new Set
    @markers = []
    @statusTiles = []

    @bottomTabFile = new BottomTab()
    @bottomTabProject = new BottomTab()
    @panel = document.createElement 'div'
    @bubble = null
    @bottomStatus = new BottomStatus()

    @bottomTabFile.initialize("File", =>
      @changeTab('file')
    )
    @bottomTabProject.initialize("Project", =>
      @changeTab('project')
    )
    @bottomStatus.initialize()
    @bottomStatus.addEventListener 'click', ->
      atom.commands.dispatch atom.views.getView(atom.workspace), 'linter:next-error'
    @panelWorkspace = atom.workspace.addBottomPanel item: @panel, visible: false

    # Set default tab to File
    @scope = 'file'
    @bottomTabFile.active = true
    @panel.id = 'linter-panel'

  getMessages: ->
    @messages

# consumed in views/panel
  setPanelVisibility: (Status) ->
    if Status
      @panelWorkspace.show() unless @panelWorkspace.isVisible()
    else
      @panelWorkspace.hide() if @panelWorkspace.isVisible()

  # Called in config observer of linter-plus.coffee
  setShowPanel: (showPanel) ->
    atom.config.set('linter.showErrorPanel', showPanel)
    @showPanel = showPanel
    if showPanel
      @panel.removeAttribute('hidden')
    else
      @panel.setAttribute('hidden', true)

  # Called in config observer of linter-plus.coffee
  setShowBubble: (@showBubble) ->

  setUnderlineIssues: (@underlineIssues) ->

  setBubbleOpaque: ->
    bubble = document.getElementById('linter-inline')
    if bubble
      bubble.classList.remove 'transparent'
    document.removeEventListener 'keyup', @setBubbleOpaque
    window.removeEventListener 'blur', @setBubbleOpaque

  setBubbleTransparent: ->
    bubble = document.getElementById('linter-inline')
    if bubble
      bubble.classList.add 'transparent'
      document.addEventListener 'keyup', @setBubbleOpaque
      window.addEventListener 'blur', @setBubbleOpaque

  # This message is called in editor-linter.coffee
  render: ->
    counts = {project: 0, file: 0}
    @messages.clear()
    @linter.eachEditorLinter (editorLinter) =>
      @extractMessages(editorLinter.getMessages(), counts)
    @extractMessages(@linter.getProjectMessages(), counts)

    @renderPanel()
    @bottomTabFile.count = counts.file
    @bottomTabProject.count = counts.project
    @bottomStatus.count = counts.project
    hasActiveEditor = typeof atom.workspace.getActiveTextEditor() isnt 'undefined'
    @bottomTabFile.visibility = hasActiveEditor
    @bottomTabProject.visibility = hasActiveEditor

  # consumed in editor-linter, _renderPanel
  updateBubble: (point) ->
    @removeBubble()
    return unless @showBubble
    return unless @messages.size
    activeEditor = atom.workspace.getActiveTextEditor()
    return unless activeEditor?.getPath()
    point = point || activeEditor.getCursorBufferPosition()
    try @messages.forEach (message) =>
      return unless message.currentFile
      return unless message.range?.containsPoint point
      @bubble = activeEditor.markBufferRange([point, point], {invalidate: 'never'})
      activeEditor.decorateMarker(
        @bubble
        {
          type: 'overlay',
          position: 'tail',
          item: @renderBubble(message)
        }
      )
      throw null

  # This method is called when we get the status-bar service
  attachBottom: (statusBar) ->
    @statusTiles.push statusBar.addLeftTile
      item: @bottomTabFile,
      priority: -1001
    @statusTiles.push statusBar.addLeftTile
      item: @bottomTabProject,
      priority: -1000
    statusIconPosition = atom.config.get('linter.statusIconPosition')
    @statusTiles.push statusBar["add#{statusIconPosition}Tile"]
      item: @bottomStatus,
      priority: -999

  # this method is called on package deactivate
  destroy: ->
    @messages.clear()
    @removeMarkers()
    @panelWorkspace.destroy()
    @removeBubble()
    for statusTile in @statusTiles
      statusTile.destroy()

  changeTab: (Tab) ->
    if @bottomTabFile.active and Tab is 'file'
      @showPanel = not @showPanel
    else if @bottomTabProject.active and Tab is 'project'
      @showPanel = not @showPanel
    else
      @showPanel = true
    @setShowPanel(@showPanel)
    if @showPanel
      @scope = Tab
      @bottomTabProject.active = Tab is 'project'
      @bottomTabFile.active = Tab is 'file'
      @renderPanel()
    else
      @bottomTabProject.active = no
      @bottomTabFile.active = no

  removeBubble: ->
    return unless @bubble
    @bubble.destroy()
    @bubble = null

  renderBubble: (message) ->
    bubble = document.createElement 'div'
    bubble.id = 'linter-inline'
    bubble.appendChild Message.fromMessage(message)
    if message.trace then message.trace.forEach (trace) ->
      bubble.appendChild Message.fromMessage(trace, addPath: true)
    bubble

  renderPanel: ->
    @panel.innerHTML = ''
    @removeMarkers()
    @removeBubble()
    if not @messages.size
      return @setPanelVisibility(false)
    @setPanelVisibility(true)
    activeEditor = atom.workspace.getActiveTextEditor()
    @messages.forEach (message) =>
      if @scope is 'file' then return unless message.currentFile
      if message.currentFile and message.range #Add the decorations to the current TextEditor
        @markers.push marker = activeEditor.markBufferRange message.range, {invalidate: 'never'}
        activeEditor.decorateMarker(
          marker, type: 'line-number', class: "linter-highlight #{message.class}"
        )
        if @underlineIssues then activeEditor.decorateMarker(
          marker, type: 'highlight', class: "linter-highlight #{message.class}"
        )
      Element = Message.fromMessage(message, addPath: @scope is 'project', cloneNode: true)
      @panel.appendChild Element
    @updateBubble()


  removeMarkers: ->
    return unless @markers.length
    for marker in @markers
      try marker.destroy()
    @markers = []

  # This method is called in render, and classifies the messages according to scope
  extractMessages: (Gen, counts) ->
    isProject = @scope is 'project'
    activeEditor = atom.workspace.getActiveTextEditor()
    activeFile = activeEditor?.getPath()
    Gen.forEach (Entry) =>
      # Entry === Array<Messages>
      Entry.forEach (message) =>
        # If there's no file prop on message and the panel scope is file then count is as current
        if activeEditor and ((not message.filePath and not isProject) or message.filePath is activeFile)
          counts.file++
          counts.project++
          message.currentFile = true
        else
          counts.project++
          message.currentFile = false
        @messages.add message
module.exports = LinterViews
