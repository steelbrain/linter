BottomTabFile = require './views/bottom-tab-file'
BottomTabProject = require './views/bottom-tab-project'
BottomStatus = require './views/bottom-status'
Panel = require './views/panel'

class LinterViews
  constructor: (@linter)->
    @messages = []

    @bottomTabFile = new BottomTabFile()
    @bottomTabProject = new BottomTabProject()
    @bottomStatus = new BottomStatus()
    @panel = new Panel

    @bottomTabFile.initialize(@linter)
    @bottomTabProject.initialize(@linter)
    @bottomStatus.initialize()
    @panel.initialize(@linter)
    @panelWorkspace = atom.workspace.addBottomPanel item: @panel, visible: false

    # Set default tab to File
    @scope = 'file'
    @bottomTabFile.active = true

  # This message is called in editor-linter.coffee
  render: ->
    return @panel.hide() unless @linter.activeEditor
    return @panel.hide() unless @linter.activeEditor?.getPath()

    counts = {project: 0, file: 0}
    activeLinter = @linter.getActiveEditorLinter()
    messages = @._extractMessages(@linter.messagesProject, counts)
    messages = messages.concat(@._extractMessages(activeLinter.messages, counts)) if activeLinter
    @messages = messages

    if messages.length
      @panel.render messages
      @panelWorkspace.show() unless @panelWorkspace.isVisible()
    else
      @panel.hide()

    @bottomTabFile.count = counts.file
    @bottomTabProject.count = counts.project
    @bottomStatus.count = counts.project

  # This method is called when we get the status-bar service
  attachBottom: (statusBar)->
    statusBar.addLeftTile
      item: @bottomTabFile,
      priority: -1001
    statusBar.addLeftTile
      item: @bottomTabProject,
      priority: -1000
    statusBar.addLeftTile
      item: @bottomStatus,
      priority: -999

  # this method is called on package deactivate
  deactivate: ->
    @panel.removeDecorations()
    @panelWorkspace.destroy()

  # This method is called in render, and classifies the messages according to scope
  _extractMessages: (Gen, counts)->
    isProject = @scope is 'project'
    activeFile = @linter.activeEditor.getPath()
    ToReturn = []
    @linter.h.genValues(Gen).forEach (Entry)->
      # Entry === Array<Messages>
      Entry.forEach (message)->
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