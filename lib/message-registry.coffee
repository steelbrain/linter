{Emitter, TextEditor, CompositeDisposable} = require('atom')
validate = require('./validate')
helpers = require('./helpers')

class MessageRegistry
  constructor: ->
    @updated = false
    @publicMessages = []
    @subscriptions = new CompositeDisposable()
    @emitter = new Emitter
    @linterResponses = new Map()
    @editorMessages = new Map()

    @subscriptions.add(@emitter)
    @subscriptions.add atom.config.observe('linter.ignoredMessageTypes', (ignoredMessageTypes) =>
      @ignoredMessageTypes = ignoredMessageTypes
    )
    @shouldUpdatePublic = true
    requestAnimationFrame => @updatePublic()

  set: ({linter, messages, editor}) ->
    try validate.messages(messages) catch e then return helpers.error(e)
    messages = messages.filter((entry) => @ignoredMessageTypes.indexOf(entry.type) is -1)
    if linter.scope is 'project'
      @linterResponses.set(linter, messages)
    else
      throw new Error("Given editor isn't really an editor") unless editor instanceof TextEditor
      if not @editorMessages.has(editor) then @editorMessages.set(editor, new Map())
      @editorMessages.get(editor).set(linter, messages)
    @updated = true

  updatePublic: ->
    return unless @shouldUpdatePublic
    if @updated
      @updated = false
      publicMessages = []
      @linterResponses.forEach (messages) -> publicMessages = publicMessages.concat(messages)
      @editorMessages.forEach (linters) -> linters.forEach (messages) ->
        publicMessages = publicMessages.concat(messages)
      @publicMessages = publicMessages
      @emitter.emit 'did-update-messages', @publicMessages
    requestAnimationFrame => @updatePublic()

  onDidUpdateMessages: (callback) ->
    return @emitter.on('did-update-messages', callback)

  deleteMessages: (linter) ->
    if @linterResponses.has(linter)
      @updated = true
      @linterResponses.delete(linter)

  deleteEditorMessages: (editor) ->
    if @editorMessages.has(editor)
      @updated = true
      @editorMessages.delete(editor)

  deactivate: ->
    @shouldUpdatePublic = false
    @subscriptions.dispose()
    @linterResponses.clear()
    @editorMessages.clear()

module.exports = MessageRegistry