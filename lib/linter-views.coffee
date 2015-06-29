BottomTab = require './views/bottom-tab'
BottomStatus = require './views/bottom-status'
Message = require './views/message'

class LinterViews
  constructor: (@state, @linter) ->
    @showPanel = true
    @showBubble = true
    @underlineIssues = true

    @messages = new Set # Classified snapshot of linter's messages when it was last updated
    @lineMessages = new Set
    @markers = []
    @statusTiles = []
    @tabPriority = ['File', 'Project', 'Line']

    @tabs =
      Line: new BottomTab()
      File: new BottomTab()
      Project: new BottomTab()

    @panel = document.createElement 'div'
    @bubble = null
    @bottomStatus = new BottomStatus()

    @bottomStatus.initialize()
    @bottomStatus.addEventListener 'click', ->
      atom.commands.dispatch atom.views.getView(atom.workspace), 'linter:next-error'
    @panelWorkspace = atom.workspace.addBottomPanel item: @panel, visible: false

    for key, tab of @tabs
      do (key, tab) =>
        tab.initialize key, => @changeTab(key)

    @panel.id = 'linter-panel'
    @updateTabs()
    @linter.subscriptions.add @linter.onDidChangeMessages =>
      @render()

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
    @classifyMessages(@linter.getMessages())
    @updateLineMessages()
    @updateBubble()
    @renderPanelMarkers()
    @renderPanelMessages()

  updateTabs: ->
    first = null
    last = null

    for key, tab of @tabs
      tab.classList.remove('first')
      tab.classList.remove('last')
      tab.visibility = atom.config.get("linter.showErrorTab#{key}")
      if tab.visibility
        last = tab
        first = tab unless first

    first.classList.add('first') if first
    last.classList.add('last') if last

    unless @tabs[@state.scope]?.visibility
      @state.scope = @tabPriority.filter((key) => @tabs[key].visibility)[0]
      @state.scope ?= 'File'

    @changeTab(@state.scope, false)

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

  updateLineMessages: (shouldRender = false) ->
    return unless @tabs.Line.visibility
    @lineMessages.clear()
    currentLine = atom.workspace.getActiveTextEditor()?.getCursorBufferPosition()?.row
    if currentLine
      @messages.forEach (message) =>
        if message.currentFile and message.range?.intersectsRow currentLine
          @lineMessages.add message
      @tabs.Line.count = @lineMessages.size
    if shouldRender then @renderPanelMessages()

  # This method is called when we get the status-bar service
  attachBottom: (statusBar) ->
    @statusTiles.push statusBar.addLeftTile
      item: @tabs.Line,
      priority: -1002
    @statusTiles.push statusBar.addLeftTile
      item: @tabs.File,
      priority: -1001
    @statusTiles.push statusBar.addLeftTile
      item: @tabs.Project,
      priority: -1000
    statusIconPosition = atom.config.get('linter.statusIconPosition')
    @statusTiles.push statusBar["add#{statusIconPosition}Tile"]
      item: @bottomStatus,
      priority: -999

  changeTab: (tabName, render = true) ->
    @showPanel = not @tabs[tabName]?.active
    if not @showPanel
      for key, tab of @tabs
        tab.active = false
    else
      @state.scope = tabName
      for key, tab of @tabs
        tab.active = tabName is key
      @renderPanelMessages() if render
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
      return if @state.scope isnt 'Project' and not message.currentFile
      if message.currentFile and message.range #Add the decorations to the current TextEditor
        @markers.push marker = activeEditor.markBufferRange message.range, {invalidate: 'never'}
        activeEditor.decorateMarker(
          marker, type: 'line-number', class: "linter-highlight #{message.class}"
        )
        if @underlineIssues then activeEditor.decorateMarker(
          marker, type: 'highlight', class: "linter-highlight #{message.class}"
        )

  renderPanelMessages: ->
    messages =
      if @tabs['Line'].active
        @lineMessages
      else
        @messages
    return @setPanelVisibility(false) unless messages.size
    @setPanelVisibility(true)
    @panel.innerHTML = ''
    messages.forEach (message) =>
      return if @state.scope isnt 'Project' and not message.currentFile
      Element = Message.fromMessage(message, addPath: @state.scope is 'Project', cloneNode: true)
      @panel.appendChild Element

  removeMarkers: ->
    return unless @markers.length
    for marker in @markers
      try marker.destroy()
    @markers = []

  # This method is called in render, and classifies the messages according to scope
  classifyMessages: (Gen) ->
    counts = {File: 0, Project: 0}
    isProject = @state.scope is 'Project'
    activeFile = atom.workspace.getActiveTextEditor()?.getPath()
    @messages.clear()
    Gen.forEach (Entry) =>
      # Entry === Array<Messages>
      Entry.forEach (message) =>
        # If there's no file prop on message and the panel scope is file then count is as current
        if (not message.filePath and not isProject) or message.filePath is activeFile
          counts.File++
          counts.Project++
          message.currentFile = true
        else
          counts.Project++
          message.currentFile = false
        @messages.add message
    @tabs.File.count = counts.File
    @tabs.Project.count = counts.Project
    @bottomStatus.count = counts.Project

  # this method is called on package deactivate
  destroy: ->
    @removeMarkers()
    @panelWorkspace.destroy()
    @removeBubble()
    for statusTile in @statusTiles
      statusTile.destroy()

module.exports = LinterViews
