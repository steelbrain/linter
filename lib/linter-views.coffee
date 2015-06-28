BottomTab = require './views/bottom-tab'
BottomStatus = require './views/bottom-status'
Message = require './views/message'

class LinterViews
  constructor: (@linter) ->
    @showPanel = true
    @showBubble = true
    @underlineIssues = true

    @messages = new Set
    @lineMessages = new Set
    @markers = []
    @statusTiles = []

    @tabs = {}
    @tabs['Line'] = new BottomTab()
    @tabs['File'] = new BottomTab()
    @tabs['Project'] = new BottomTab()

    @panel = document.createElement 'div'
    @bubble = null
    @bottomStatus = new BottomStatus()

    @tabs['Line'].initialize 'Line', => @changeTab('Line')
    @tabs['File'].initialize 'File', => @changeTab('File')
    @tabs['Project'].initialize 'Project', => @changeTab('Project')

    @bottomStatus.initialize()
    @bottomStatus.addEventListener 'click', ->
      atom.commands.dispatch atom.views.getView(atom.workspace), 'linter:next-error'
    @panelWorkspace = atom.workspace.addBottomPanel item: @panel, visible: false

    @scope = atom.config.get('linter.defaultErrorTab')
    for key, tab of @tabs
      tab.active = @scope is key

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

    @updateLineMessages()
    @updateBubble()
    @renderPanelMarkers()
    @renderPanelMessages()
    @tabs['File'].count = counts.file
    @tabs['Project'].count = counts.project
    @bottomStatus.count = counts.project

  updateTabs: ->
    first = null
    last = null
    for key, tab of @tabs # for...of (key, value)
      tab.classList.remove('first')
      tab.classList.remove('last')
      tab.visibility = atom.config.get("linter.showErrorTab#{key}")
      if tab.visibility
        if first then last = tab
        else first = tab
    first.classList.add('first') if first
    last.classList.add('last') if last

  # consumed in editor-linter, renderPanel
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

  updateLineMessages: (line, shouldRender = false) ->
    return if @currentLine is line
    return unless @tabs['Line'].visibility
    @currentLine = line
    @lineMessages.clear()
    if @linter.getActiveEditorLinter()
      @messages.forEach (message) =>
        if message.currentFile and message.range?.intersectsRow @currentLine
          @lineMessages.add message
      @tabs['Line'].count = @lineMessages.length
    if shouldRender then @renderPanelMessages()

  # This method is called when we get the status-bar service
  attachBottom: (statusBar) ->
    @statusTiles.push statusBar.addLeftTile
      item: @tabs['Line'],
      priority: -1002
    @statusTiles.push statusBar.addLeftTile
      item: @tabs['File'],
      priority: -1001
    @statusTiles.push statusBar.addLeftTile
      item: @tabs['Project'],
      priority: -1000
    statusIconPosition = atom.config.get('linter.statusIconPosition')
    @statusTiles.push statusBar["add#{statusIconPosition}Tile"]
      item: @bottomStatus,
      priority: -999

  changeTab: (Tab) ->
    atom.config.set('linter.defaultErrorTab', Tab)
    @showPanel = @scope isnt Tab
    if not @showPanel
      for key, tab of @tabs
        tab.active = false
    else
      @scope = Tab
      for key, tab of @tabs
        tab.active = Tab is key
      @renderPanelMessages()
    @setShowPanel @showPanel

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

  renderPanelMarkers: ->
    @removeMarkers()
    activeEditor = atom.workspace.getActiveTextEditor()
    @messages.forEach (message) =>
      return if @scope isnt 'Project' and not message.currentFile
      if message.currentFile and message.range #Add the decorations to the current TextEditor
        @markers.push marker = activeEditor.markBufferRange message.range, {invalidate: 'never'}
        activeEditor.decorateMarker(
          marker, type: 'line-number', class: "linter-highlight #{message.class}"
        )
        if @underlineIssues then activeEditor.decorateMarker(
          marker, type: 'highlight', class: "linter-highlight #{message.class}"
        )

  renderPanelMessages: ->
    messages = null
    if @tabs['Line'].active
      messages = @lineMessages
    else
      messages = @messages
    return @setPanelVisibility(false) unless messages.size
    @setPanelVisibility(true)
    @panel.innerHTML = ''
    messages.forEach (message) =>
      return if @scope isnt 'Project' and not message.currentFile
      Element = Message.fromMessage(message, addPath: @scope is 'Project', cloneNode: true)
      @panel.appendChild Element

  removeMarkers: ->
    return unless @markers.length
    for marker in @markers
      try marker.destroy()
    @markers = []

  # This method is called in render, and classifies the messages according to scope
  extractMessages: (Gen, counts) ->
    isProject = @scope is 'Project'
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

  # this method is called on package deactivate
  destroy: ->
    @messages.clear()
    @removeMarkers()
    @panelWorkspace.destroy()
    @removeBubble()
    for statusTile in @statusTiles
      statusTile.destroy()

module.exports = LinterViews
