{CompositeDisposable} = require 'atom'

class Commands
  constructor: (@linter) ->
    @_subscriptions = new CompositeDisposable
    @_subscriptions.add atom.commands.add 'atom-workspace',
      'linter:next-error': => @nextMessage('error')
      'linter:next-warning': => @nextMessage('warning')
      'linter:toggle': => @toggleLinter()
      'linter:set-bubble-transparent': => @setBubbleTransparent()
      'linter:lint': => @lint()

    # Default values
    @_messages = null

  toggleLinter: ->
    @linter.getActiveEditorLinter()?.toggleStatus()

  setBubbleTransparent: ->
    @linter.views.setBubbleTransparent()

  lint: ->
    try
      @linter.getActiveEditorLinter()?.lint(false)
      @linter.views.render()

    catch error
      atom.notifications.addError error.message, {detail: error.stack, dismissable: true}

  # Recursive find until it matches correct type
  getNextMessage: (messages, type) ->
    next = messages.next()
    return next if next.done
    return next if next.value.type is type
    return @getNextMessage messages, type

  nextMessage: (type) ->
    if not @_messages or (next = @getNextMessage(@_messages, type)).done
      @_messages = @linter.views.getMessages().values()
      next = @getNextMessage @_messages, type

    return if next.done # There's no errors
    message = next.value
    return unless message.filePath
    return unless message.range
    atom.workspace.open(message.filePath).then ->
      atom.workspace.getActiveTextEditor().setCursorBufferPosition(message.range.start)

  destroy: ->
    @_messages = null
    @_subscriptions.dispose()

module.exports = Commands
