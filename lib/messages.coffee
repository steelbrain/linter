

class MessageRegistry
  constructor: (@linter)->
    @messages = new Map()

  set: (linter, messages) ->
    @classifyMessages(messages)
    @messages.set(linter, messages)

  delete: (linter) ->
    @messages.delete(linter)

  get: ->
    @messages

  classifyMessages: (messages)->
    isProject = @linter.state.scope is 'Project'
    activeFile = atom.workspace.getActiveTextEditor()?.getPath()
    messages.forEach (message) =>
      if (not message.filePath and not isProject) or message.filePath is activeFile
        message.currentFile = true
      else
        message.currentFile = false


module.exports = MessageRegistry