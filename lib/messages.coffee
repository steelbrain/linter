Helpers = require('./helpers')
{CompositeDisposable, Emitter} = require 'atom'

###
  Note: We are reclassifying the messages on on Pane Item Change,
  even though we are relinting on that same event, 'cause linters
  could take time and we have to refresh the views immediately
###

class MessageRegistry
  constructor: (@linter)->
    @count = File: 0, Project: 0
    @messages = new Map() # Messages = Map<Linter, Array<messages>>
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

  getCount: ->
    return File: @count.File, Project: @count.Project

  getAllMessages: ->
    toReturn = []
    @messages.forEach (messages) =>
      toReturn = toReturn.concat(messages)
    return toReturn

  getActiveFileMessages: ->
    toReturn = []
    @messages.forEach (messages) =>
      toReturn = toReturn.concat(messages.filter((message) -> message.currentFile))
    return toReturn

  getActiveFileMessagesForRow: (row)->
    toReturn = []
    @messages.forEach (messages) =>
      toReturn = toReturn.concat messages.filter((message) ->
        message.currentFile and message.range?.intersectsRow row
      )
    return toReturn

  onDidChange: (callback) ->
    return @emitter.on 'did-change', callback

  onDidClassify: (callback) ->
    return @emitter.on 'did-classify', callback

  classifyMessages: (messages)->
    @count = File: 0, Project: 0
    isProject = @linter.state.scope is 'Project'
    activeFile = atom.workspace.getActiveTextEditor()?.getPath()
    messages.forEach (message) =>
      @count.Project++
      if (not message.filePath and not isProject) or message.filePath is activeFile
        message.currentFile = true
        @count.File++
      else
        message.currentFile = false

  destroy: ->
    @messages.clear()
    @subscriptions.dispose()
    @emitter.dispose()


module.exports = MessageRegistry
