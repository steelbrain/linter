Helpers = require('./helpers')
{CompositeDisposable, Emitter} = require 'atom'

class MessageRegistry
  constructor: (@linter)->
    @messages = new Map()
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem =>
      @messages.forEach (messages) => @classifyMessages(messages)
      @emitter.emit 'did-classify'

  set: (linter, messages) ->
    Helpers.validateMessages(messages)
    @classifyMessages(messages)
    @messages.set(linter, messages)
    @emitter.emit 'did-classify'
    @emitter.emit 'did-change', @messages

  delete: (linter) ->
    @messages.delete(linter)
    @emitter.emit 'did-change', @messages

  get: ->
    return @messages

  onDidChange: (callback) ->
    return @emitter.on 'did-change', callback

  onDidClassify: (callback) ->
    return @emitter.on 'did-classify', callback

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
    @subscriptions.dispose()
    @emitter.dispose()


module.exports = MessageRegistry