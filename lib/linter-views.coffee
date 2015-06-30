{CompositeDisposable} = require 'atom'
BottomTab = require './views/bottom-tab'
BottomStatus = require './views/bottom-status'
Message = require './views/message'

class LinterViews
  constructor: (@state, @linter) ->
    @showPanel = true
    @showBubble = true
    @underlineIssues = true

    @subscriptions = new CompositeDisposable
    @messages = [] # Value returned by MessageRegistry::getAll
    @lineMessages = []
    @markers = []
    @statusTiles = []

    @tabPriority = ['File', 'Project', 'Line']

    @tabs =
      Line: new BottomTab()
      File: new BottomTab()
      Project: new BottomTab()

    @panel = document.createElement 'div'
    @panel.id = 'linter-panel'
    @bubble = null
    @bottomStatus = new BottomStatus()

    @bottomStatus.addEventListener 'click', ->
      atom.commands.dispatch atom.views.getView(atom.workspace), 'linter:next-error'
    @panelWorkspace = atom.workspace.addBottomPanel item: @panel, visible: false

    for key, tab of @tabs
      do (key, tab) =>
        tab.initialize key, => @changeTab(key)
    @updateTabs()
    @subscriptions.add @linter.onDidClassifyMessages =>
      @render()

  # consumed in views/panel
  setPanelWorkspaceVisibility: (Status) ->
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
    @messages = @linter.messages.getAllMessages()
    @updateTabCounts()
    @updateBubble()
    @renderPanelMarkers()
    @updateLineMessages()
    @renderPanelMessages()

  updateTabCounts: ->
    @tabs.File.count = @linter.messages.count.File
    @tabs.Project.count = @linter.messages.count.Project
    @bottomStatus.count = @linter.messages.count.Project

  updateBubble: (point) ->
    @removeBubble()
    return unless @showBubble
    return unless @messages.length
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

  updateLineMessages: (shouldRender = false) ->
    return unless @tabs.Line.visibility
    row = atom.workspace.getActiveTextEditor()?.getCursorBufferPosition()?.row
    @lineMessages = @linter.messages.getActiveFileMessagesForRow(row)
    @tabs.Line.count = @lineMessages.length
    if shouldRender then @renderPanelMessages()

  renderPanelMessages: ->
    messages =
      if @tabs['Line'].active
        @lineMessages
      else
        @messages
    return @setPanelWorkspaceVisibility(false) unless messages.length
    @setPanelWorkspaceVisibility(true)
    @panel.innerHTML = ''
    messages.forEach (message) =>
      return if @state.scope isnt 'Project' and not message.currentFile
      Element = Message.fromMessage(message, addPath: @state.scope is 'Project', cloneNode: true)
      @panel.appendChild Element

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

  removeMarkers: ->
    return unless @markers.length
    for marker in @markers
      try marker.destroy()
    @markers = []

  # this method is called on package deactivate
  destroy: ->
    @removeMarkers()
    @panelWorkspace.destroy()
    @removeBubble()
    @subscriptions.dispose()
    for statusTile in @statusTiles
      statusTile.destroy()

module.exports = LinterViews
