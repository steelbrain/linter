{Emitter} = require('atom')
validate = require('./validate')
helpers = require('./helpers')

class MessageRegistry
  constructor: ->
    @updated = false
    @publicMessages = []
    @emitter = new Emitter
    @messages = new Map()
    @editorMessages = new Map()

    @shouldUpdatePublic = true
    requestAnimationFrame => @updatePublic()

  set: ({linter, messages, editor}) ->
    try validate.messages(messages) catch e then return helpers.error(e)
    if linter.scope is 'project'
      @messages.set(linter, messages)
    else
      if not @editorMessages.has(editor) then @editorMessages.set(editor, new Map())
      @editorMessages.get(editor).set(linter, messages)
    @updated = true

  updatePublic: ->
    return unless @shouldUpdatePublic
    if @updated
      @updated = false
      publicMessages = []
      @messages.forEach (messages) -> publicMessages = publicMessages.concat(messages)
      @editorMessages.forEach (linters) -> linters.forEach (messages) ->
        publicMessages = publicMessages.concat(messages)
      @publicMessages = publicMessages.sort (a, b) ->
        return -1 if a < b
        return 1 if a > b
        return 0
      @emitter.emit 'did-update-messages', @publicMessages
    requestAnimationFrame => @updatePublic()

  onDidUpdateMessages: (callback) ->
    return @emitter.on('did-update-messages', callback)

  deleteEditorMessages: (editor) ->
    if @editorMessages.has(editor)
      @updated = true
      @editorMessages.delete(editor)

  deactivate: ->
    @shouldUpdatePublic = false
    @emitter.dispose()
    @messages.clear()
    @editorMessages.clear()

module.exports = MessageRegistry
