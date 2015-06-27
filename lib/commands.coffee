{CompositeDisposable} = require 'atom'

class Commands
  constructor: (@linter) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'linter:next-error': => @nextError()
      'linter:toggle': => @toggleLinter()
      'linter:set-bubble-transparent': => @setBubbleTransparent()
      'linter:lint': => @lint()

    # Default values
    @messages = null

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

  nextError: ->
    if not @messages or (next = @messages.next()).done
      next = (@messages = @linter.views.getMessages().values()).next()
    return if next.done # There's no errors
    message = next.value
    return unless message.filePath
    return unless message.range
    atom.workspace.open(message.filePath).then ->
      atom.workspace.getActiveTextEditor().setCursorBufferPosition(message.range.start)

  destroy: ->
    @messages = null
    @subscriptions.dispose()

module.exports = Commands
