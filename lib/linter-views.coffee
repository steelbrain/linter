BottomTab = require './views/bottom-tab'
BottomStatus = require './views/bottom-status'
Message = require './views/message'

class LinterViews
  constructor: (@linter) ->
    @_showPanel = true # Altered by config observer in linter-plus
    @_showBubble = true # Altered by the config observer in linter-plus
    @_underlineIssues = true # Altered by config observer in linter-plus

    @_messages = new Set
    @_markers = []
    @_statusTiles = []

    @_tabs = new Map
    @_tabs.set 'line', new BottomTab()
    @_tabs.set 'file', new BottomTab()
    @_tabs.set 'project', new BottomTab()

    @_panel = document.createElement 'div'
    @_bubble = null
    @_bottomStatus = new BottomStatus()

    @_tabs.get('line').initialize 'Line', => @_changeTab('line')
    @_tabs.get('file').initialize 'File', => @_changeTab('file')
    @_tabs.get('project').initialize 'Project', => @_changeTab('project')

    @_bottomStatus.initialize()
    @_bottomStatus.addEventListener 'click', ->
      atom.commands.dispatch atom.views.getView(atom.workspace), 'linter:next-error'
    @_panelWorkspace = atom.workspace.addBottomPanel item: @_panel, visible: false

    # Set default tab
    visibleTabs = @_getVisibleTabKeys()

    @_scope = atom.config.get('linter.defaultErrorTab', 'file')
    if visibleTabs.indexOf(@_scope) is -1
      @_scope = visibleTabs[0]

    @_tabs.forEach (tab, key) =>
      tab.visible = false
      tab.active = @_scope is key

    @_panel.id = 'linter-panel'

  getMessages: ->
    @_messages

# consumed in views/panel
  setPanelVisibility: (Status) ->
    if Status
      @_panelWorkspace.show() unless @_panelWorkspace.isVisible()
    else
      @_panelWorkspace.hide() if @_panelWorkspace.isVisible()

  # Called in config observer of linter-plus.coffee
  setShowPanel: (showPanel) ->
    atom.config.set('linter.showErrorPanel', showPanel)
    @_showPanel = showPanel
    if showPanel
      @_panel.removeAttribute('hidden')
    else
      @_panel.setAttribute('hidden', true)

  # Called in config observer of linter-plus.coffee
  setShowBubble: (@_showBubble) ->

  setUnderlineIssues: (@_underlineIssues) ->

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
    @_messages.clear()
    @linter.eachEditorLinter (editorLinter) =>
      @_extractMessages(editorLinter.getMessages(), counts)
    @._extractMessages(@linter.getProjectMessages(), counts)

    @_updateLineMessages()

    @_renderPanel()
    @_tabs.get('file').count = counts.file
    @_tabs.get('project').count = counts.project
    @_bottomStatus.count = counts.project
    hasActiveEditor = typeof atom.workspace.getActiveTextEditor() isnt 'undefined'

    visibleTabs = @_getVisibleTabKeys()

    @_tabs.forEach (tab, key) ->
      tab.visibility = hasActiveEditor and visibleTabs.indexOf(key) isnt -1
      tab.classList.remove 'first-tab'
      tab.classList.remove 'last-tab'

    if visibleTabs.length > 0
      @_tabs.get(visibleTabs[0]).classList.add 'first-tab'
      @_tabs.get(visibleTabs[visibleTabs.length - 1]).classList.add 'last-tab'


  # consumed in editor-linter, _renderPanel
  updateBubble: (point) ->
    @_removeBubble()
    return unless @_showBubble
    return unless @_messages.size
    activeEditor = atom.workspace.getActiveTextEditor()
    return unless activeEditor?.getPath()
    point = point || activeEditor.getCursorBufferPosition()
    try @_messages.forEach (message) =>
      return unless message.currentFile
      return unless message.range?.containsPoint point
      @_bubble = activeEditor.markBufferRange([point, point], {invalidate: 'never'})
      activeEditor.decorateMarker(
        @_bubble
        {
          type: 'overlay',
          position: 'tail',
          item: @_renderBubble(message)
        }
      )
      throw null

  updateCurrentLine: (line) ->
    if @_currentLine isnt line
      @_currentLine = line
      @_updateLineMessages()


  _updateLineMessages: ->
    activeEditor = atom.workspace.getActiveTextEditor()
    @linter.eachEditorLinter (editorLinter) =>
      return unless editorLinter.editor is activeEditor

      @_lineMessages = []
      editorLinter.getMessages().forEach (Gen) =>
        Gen.forEach (message) =>
          @_lineMessages.push message if message.range?.intersectsRow @_currentLine

      @_tabs.get('line').count = @_lineMessages.length
      @_renderPanel()

  # This method is called when we get the status-bar service
  attachBottom: (statusBar) ->
    @_statusTiles.push statusBar.addLeftTile
      item: @_tabs.get('line'),
      priority: -1002
    @_statusTiles.push statusBar.addLeftTile
      item: @_tabs.get('file'),
      priority: -1001
    @_statusTiles.push statusBar.addLeftTile
      item: @_tabs.get('project'),
      priority: -1000
    @_statusTiles.push statusBar.addRightTile
      item: @_bottomStatus,
      priority: 999

  # this method is called on package deactivate
  destroy: ->
    @_messages.clear()
    @_removeMarkers()
    @_panelWorkspace.destroy()
    @_removeBubble()
    for statusTile in @_statusTiles
      statusTile.destroy()

  _changeTab: (Tab) ->
    if @_getActiveTabKey() is Tab
      @_showPanel = not @_showPanel
      @_tabs.forEach (tab, key) -> tab.active = false
    else
      @_showPanel = true
      @_scope = Tab
      @_tabs.forEach (tab, key) -> tab.active = Tab is key
      @_renderPanel()
    @setShowPanel @_showPanel

  _getActiveTabKey: ->
    activeKey = null
    @_tabs.forEach (tab, key) -> activeKey = key if tab.active
    return activeKey

  _getActiveTab: ->
    @_tabs.entries().find (tab) -> tab.active

  _getVisibleTabKeys: ->
    return [
      'line'    if atom.config.get('linter.showErrorTabLine')
      'file'    if atom.config.get('linter.showErrorTabFile')
      'project' if atom.config.get('linter.showErrorTabProject')
    ].filter (key) -> key

  _removeBubble: ->
    return unless @_bubble
    @_bubble.destroy()
    @_bubble = null

  _renderBubble: (message) ->
    bubble = document.createElement 'div'
    bubble.id = 'linter-inline'
    bubble.appendChild Message.fromMessage(message)
    if message.trace then message.trace.forEach (trace) ->
      bubble.appendChild Message.fromMessage(trace, addPath: true)
    bubble

  _renderPanel: ->
    @_panel.innerHTML = ''
    @_removeMarkers()
    @_removeBubble()
    if not @_messages.size
      return @setPanelVisibility(false)
    @setPanelVisibility(true)
    activeEditor = atom.workspace.getActiveTextEditor()
    @_messages.forEach (message) =>
      if @_scope is 'file' then return unless message.currentFile
      if @_underlineIssues and message.currentFile and message.range #Add the decorations to the current TextEditor
        @_markers.push marker = activeEditor.markBufferRange message.range, {invalidate: 'never'}
        activeEditor.decorateMarker(
          marker, type: 'line-number', class: "linter-highlight #{message.class}"
        )
        activeEditor.decorateMarker(
          marker, type: 'highlight', class: "linter-highlight #{message.class}"
        )

      if @_scope is 'line'
        return if @_lineMessages.indexOf(message) is -1

      Element = Message.fromMessage(message, addPath: @_scope is 'project', cloneNode: true)

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
        @_messages.add message

module.exports = LinterViews
