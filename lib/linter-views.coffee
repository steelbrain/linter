BottomTabFile = require './views/bottom-tab-file'
BottomTabProject = require './views/bottom-tab-project'
BottomStatus = require './views/bottom-status'
Panel = require './views/panel'
Bubble = require './views/bubble'

class LinterViews
  constructor: (@linter) ->
    @messages = []

    @_bottomTabFile = new BottomTabFile()
    @_bottomTabProject = new BottomTabProject()
    @_panel = new Panel
    @_bottomStatus = new BottomStatus()

    @_bottomTabFile.initialize(@linter)
    @_bottomTabProject.initialize(@linter)
    @_panel.initialize(@linter)
    @_bottomStatus.initialize()
    @_panelWorkspace = atom.workspace.addBottomPanel item: @_panel, visible: false

    # Set default tab to File
    @scope = 'file' # the value of @scope is changed from views/bottom-tab-{file, project}
    @_bottomTabFile.active = true

    # Bubble
    @linter.subscriptions.add atom.config.observe 'linter.showErrorInline', (showErrorInline) =>
      if showErrorInline
        @bubble = new Bubble @linter
      else
        @bubble?.remove()
        @bubble = null

  # This message is called in editor-linter.coffee
  render: ->
    return @_panel.hide() unless @linter.activeEditor
    return @_panel.hide() unless @linter.activeEditor.getPath?()

    counts = {project: 0, file: 0}
    activeLinter = @linter.getActiveEditorLinter()
    messages = @._extractMessages(@linter.messagesProject, counts)
    messages = messages.concat(@._extractMessages(activeLinter.messages, counts)) if activeLinter
    @messages = messages

    @_panel.update()

    @_bottomTabFile.count = counts.file
    @_bottomTabProject.count = counts.project
    @_bottomStatus.count = counts.project

  # consumed in views/bottom-tab-{file, project}
  update: ->
    @_panel.update()

  # consumed in views/bottom-tab-{file, project}
  changeTab: (Tab)->
    @scope = Tab
    @_bottomTabProject.active = Tab is 'project'
    @_bottomTabFile.active = Tab is 'file'

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