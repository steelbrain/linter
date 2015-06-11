BottomTabFile = require './views/bottom-tab-file'
BottomTabProject = require './views/bottom-tab-project'
BottomStatus = require './views/bottom-status'
Panel = require './views/panel'
Bubble = require './views/bubble'

class LinterViews
  constructor: (@linter) ->
    @messages = []

    @bottomTabFile = new BottomTabFile() # consumed in views/bottom-tab-project
    @bottomTabProject = new BottomTabProject() # consumed in views/bottom-tab-file
    @panel = new Panel # consumed in views/bottom-tab-{file, project}
    @_bottomStatus = new BottomStatus()

    @bottomTabFile.initialize(@linter)
    @bottomTabProject.initialize(@linter)
    @panel.initialize(@linter)
    @_bottomStatus.initialize()
    @panelWorkspace = atom.workspace.addBottomPanel item: @panel, visible: false

    # Set default tab to File
    @scope = 'file' # the value of @scope is changed from views/bottom-tab-{file, project}
    @bottomTabFile.active = true

    # Bubble
    @linter.subscriptions.add atom.config.observe 'linter.showErrorInline', (showErrorInline) =>
      if showErrorInline
        @bubble = new Bubble @linter
      else
        @bubble?.remove()
        @bubble = null

  # This message is called in editor-linter.coffee
  render: ->
    return @panel.hide() unless @linter.activeEditor
    return @panel.hide() unless @linter.activeEditor.getPath?()

    counts = {project: 0, file: 0}
    activeLinter = @linter.getActiveEditorLinter()
    messages = @._extractMessages(@linter.messagesProject, counts)
    messages = messages.concat(@._extractMessages(activeLinter.messages, counts)) if activeLinter
    @messages = messages

    @panel.update()

    @bottomTabFile.count = counts.file
    @bottomTabProject.count = counts.project
    @_bottomStatus.count = counts.project

  # This method is called when we get the status-bar service
  attachBottom: (statusBar) ->
    statusBar.addLeftTile
      item: @bottomTabFile,
      priority: -1001
    statusBar.addLeftTile
      item: @bottomTabProject,
      priority: -1000
    statusBar.addLeftTile
      item: @_bottomStatus,
      priority: -999

  # this method is called on package deactivate
  deactivate: ->
    @panel.removeDecorations()
    @panelWorkspace.destroy()
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