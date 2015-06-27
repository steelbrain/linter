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

    @tabs = new Map
    @tabs.set 'line', new BottomTab()
    @tabs.set 'file', new BottomTab()
    @tabs.set 'project', new BottomTab()

    @panel = document.createElement 'div'
    @bubble = null
    @bottomStatus = new BottomStatus()

    @tabs.get('line').initialize 'Line', => @changeTab('line')
    @tabs.get('file').initialize 'File', => @changeTab('file')
    @tabs.get('project').initialize 'Project', => @changeTab('project')

    @bottomStatus.initialize()
    @bottomStatus.addEventListener 'click', ->
      atom.commands.dispatch atom.views.getView(atom.workspace), 'linter:next-error'
    @panelWorkspace = atom.workspace.addBottomPanel item: @panel, visible: false

    # Set default tab
    visibleTabs = @getVisibleTabKeys()

    @scope = atom.config.get('linter.defaultErrorTab', 'File')?.toLowerCase()
    if visibleTabs.indexOf(@scope) is -1
      @scope = visibleTabs[0]

    @tabs.forEach (tab, key) =>
      tab.visible = false
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

    @renderPanel()
    @tabs.get('file').count = counts.file
    @tabs.get('project').count = counts.project
    @bottomStatus.count = counts.project
    hasActiveEditor = typeof atom.workspace.getActiveTextEditor() isnt 'undefined'

    visibleTabs = @getVisibleTabKeys()

    @tabs.forEach (tab, key) ->
      tab.visibility = hasActiveEditor and visibleTabs.indexOf(key) isnt -1
      tab.classList.remove 'first-tab'
      tab.classList.remove 'last-tab'

    if visibleTabs.length > 0
      @tabs.get(visibleTabs[0]).classList.add 'first-tab'
      @tabs.get(visibleTabs[visibleTabs.length - 1]).classList.add 'last-tab'

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

  updateCurrentLine: (line) ->
    if @currentLine isnt line
      @currentLine = line
      @updateLineMessages()
      @renderPanel()


  updateLineMessages: ->
    activeEditor = atom.workspace.getActiveTextEditor()
    @linter.eachEditorLinter (editorLinter) =>
      return unless editorLinter.editor is activeEditor

      @lineMessages = []
      @messages.forEach (message) =>
        if message.currentFile and message.range?.intersectsRow @currentLine
          @lineMessages.push message
      @tabs.get('line').count = @lineMessages.length

  # This method is called when we get the status-bar service
  attachBottom: (statusBar) ->
    @statusTiles.push statusBar.addLeftTile
      item: @tabs.get('line'),
      priority: -1002
    @statusTiles.push statusBar.addLeftTile
      item: @tabs.get('file'),
      priority: -1001
    @statusTiles.push statusBar.addLeftTile
      item: @tabs.get('project'),
      priority: -1000
    statusIconPosition = atom.config.get('linter.statusIconPosition')
    @statusTiles.push statusBar["add#{statusIconPosition}Tile"]
      item: @bottomStatus,
      priority: 999

  # this method is called on package deactivate
  destroy: ->
    @messages.clear()
    @removeMarkers()
    @panelWorkspace.destroy()
    @removeBubble()
    for statusTile in @statusTiles
      statusTile.destroy()

  changeTab: (Tab) ->
    if @getActiveTabKey() is Tab
      @showPanel = not @showPanel
      @tabs.forEach (tab, key) -> tab.active = false
    else
      @showPanel = true
      @scope = Tab
      @tabs.forEach (tab, key) -> tab.active = Tab is key
      @renderPanel()
    @setShowPanel @showPanel

  getActiveTabKey: ->
    activeKey = null
    @tabs.forEach (tab, key) -> activeKey = key if tab.active
    return activeKey

  getActiveTab: ->
    @tabs.entries().find (tab) -> tab.active

  getVisibleTabKeys: ->
    return [
      'line'    if atom.config.get('linter.showErrorTabLine')
      'file'    if atom.config.get('linter.showErrorTabFile')
      'project' if atom.config.get('linter.showErrorTabProject')
    ].filter (key) -> key

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

      if @scope is 'line'
        return if @lineMessages.indexOf(message) is -1

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
