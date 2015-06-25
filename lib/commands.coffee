{CompositeDisposable} = require 'atom'

class Commands
  constructor: (@linter) ->
    @_subscriptions = new CompositeDisposable
    @_subscriptions.add atom.commands.add 'atom-workspace',
      'linter:next-error': @nextError.bind(@)
      'linter:toggle': @toggleLinter.bind(@)
      'linter:set-bubble-transparent': @setBubleTransparent.bind(@)

    # Default values
    @_messages = null

  toggleLinter: ->
    activeEditorLinter = @linter.getActiveEditorLinter()
    return unless activeEditorLinter
    activeEditorLinter.toggleStatus()

  setBubleTransparent: ->
    @linter.getActiveEditorLinter()?.setBubbleTransparent()

  nextError: ->
    if not @_messages or (next = @_messages.next()).done
      next = (@_messages = @linter.views.getMessages().values()).next()
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
