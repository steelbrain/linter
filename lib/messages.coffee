Helpers = require('./helpers')
{CompositeDisposable, Emitter} = require('atom')

###
  Note: We are reclassifying the messages on on Pane Item Change,
  even though we are relinting on that same event, 'cause linters
  could take time and we have to refresh the views immediately
###

class MessageRegistry
  constructor: (@linter) ->
    @count = File: 0, Project: 0
    @messages = new Map() # Messages = Map<Linter, Array<message>>
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @subscriptions.add @linter.observeEditorLinters (EditorLinter) =>
      EditorLinter.onShouldUpdate ({linter, results: messages}) =>
        Helpers.validateMessages(messages)
        @classifyMessages(messages)
        if EditorLinter.messages.has(linter)
          @countMessages(EditorLinter.messages.get(linter), false)
        EditorLinter.messages.set(linter, messages)
        @countMessages(messages)
        @emitter.emit 'did-change'
      EditorLinter.onDidDestroy =>
        EditorLinter.messages.forEach (messages) =>
          @countMessages(messages, false)
          @emitter.emit 'did-change'
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem =>
      @count = File: 0, Project: 0
      @messages.forEach (messages) =>
        @classifyMessages(messages)
        @countMessages(messages)
      @linter.eachEditorLinter (EditorLinter) =>
        EditorLinter.messages.forEach (messages) =>
          @classifyMessages(messages)
          @countMessages(messages)
      @emitter.emit 'did-change'

  set: (linter, messages) ->
    Helpers.validateMessages(messages)
    @classifyMessages(messages)
    if @messages.has(linter)
      @countMessages(@messages.get(linter), false)
    @messages.set(linter, messages)
    @countMessages(messages)
    @emitter.emit 'did-change'

  delete: (linter) ->
    if @messages.has(linter)
      @countMessages(@messages.get(linter))
      @messages.delete(linter, false)
      @emitter.emit 'did-change'

  getCount: ->
    return File: @count.File, Project: @count.Project

  getAllMessages: ->
    toReturn = []
    @messages.forEach (messages) ->
      toReturn = toReturn.concat(messages)
    @linter.eachEditorLinter (EditorLinter) ->
      EditorLinter.messages.forEach (messages) ->
        toReturn = toReturn.concat(messages)
    return toReturn

  getActiveFileMessages: ->
    toReturn = []
    @messages.forEach (messages) ->
      toReturn = toReturn.concat(messages.filter((message) -> message.currentFile))
    @linter.eachEditorLinter (EditorLinter) ->
      EditorLinter.messages.forEach (messages) ->
        toReturn = toReturn.concat(messages.filter((message) -> message.currentFile))
    return toReturn

  getActiveFileMessagesForActiveRow: ->
    return @getActiveFileMessagesForRow(atom.workspace.getActiveTextEditor()?.getCursorBufferPosition()?.row)

  getActiveFileMessagesForRow: (row) ->
    toReturn = []
    @messages.forEach (messages) ->
      toReturn = toReturn.concat messages.filter((message) ->
        message.currentFile and message.range?.intersectsRow row
      )
    @linter.eachEditorLinter (EditorLinter) ->
      EditorLinter.messages.forEach (messages) ->
        toReturn = toReturn.concat messages.filter((message) ->
          message.currentFile and message.range?.intersectsRow row
        )
    return toReturn

  onDidChange: (callback) ->
    return @emitter.on 'did-change', callback

  classifyMessages: (messages) ->
    isProject = @linter.state.scope is 'Project'
    activeFile = atom.workspace.getActiveTextEditor()?.getPath()
    messages.forEach (message) ->
      if (not message.filePath and not isProject) or message.filePath is activeFile
        message.currentFile = true
      else
        message.currentFile = false

  countMessages: (messages, add = true) ->
    count = File: 0, Project: (messages.length || messages.size || 0 )
    messages.forEach (message) ->
      count.File++ if message.currentFile
    if add
      @count.File += count.File
      @count.Project += count.Project
    else
      @count.File -= count.File
      @count.Project -= count.Project

  destroy: ->
    @messages.clear()
    @subscriptions.dispose()
    @emitter.dispose()


module.exports = MessageRegistry
