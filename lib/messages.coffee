Helpers = require('./helpers')
{Emitter} = require 'atom'

class MessageRegistry
  constructor: (@linter)->
    @messages = new Map()
    @emitter = new Emitter

  set: (linter, messages) ->
    Helpers.validateMessages(messages)
    @classifyMessages(messages)
    @messages.set(linter, messages)
    @emitter.emit 'did-change', @messages

  delete: (linter) ->
    @messages.delete(linter)
    @emitter.emit 'did-change', @messages

  get: ->
    return @messages

  onDidChange: (callback) ->
    return @emitter.on 'did-change', callback

  classifyMessages: (messages)->
    isProject = @linter.state.scope is 'Project'
    activeFile = atom.workspace.getActiveTextEditor()?.getPath()
    messages.forEach (message) =>
      if (not message.filePath and not isProject) or message.filePath is activeFile
        message.currentFile = true
      else
        message.currentFile = false

  destroy: ->
    @messages.clear()
    @emitter.dispose()


module.exports = MessageRegistry