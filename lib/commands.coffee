{CompositeDisposable} = require 'atom'

class Commands
  constructor: (@linter) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'linter:next-error': => @nextError()
      'linter:previous-error': => @previousError()
      'linter:toggle': => @toggleLinter()
      'linter:set-bubble-transparent': => @setBubbleTransparent()
      'linter:expand-multiline-messages': => @expandMultilineMessages()
      'linter:lint': => @lint()

    # Default values
    @messages = null
    @index = 0

  toggleLinter: ->
    @linter.getActiveEditorLinter()?.toggleStatus()

  setBubbleTransparent: ->
    @linter.views.setBubbleTransparent()

  expandMultilineMessages: ->
    for elem in document.getElementsByTagName 'linter-multiline-message'
      elem.classList.add 'expanded'
    document.addEventListener 'keyup', @collapseMultilineMessages
    window.addEventListener 'blur', @collapseMultilineMessages

  collapseMultilineMessages: ->
    for elem in document.getElementsByTagName 'linter-multiline-message'
      elem.classList.remove 'expanded'
    document.removeEventListener 'keyup', @collapseMultilineMessages
    window.removeEventListener 'blur', @collapseMultilineMessages

  lint: ->
    try
      @linter.getActiveEditorLinter()?.lint(false)
      @linter.views.render()

    catch error
      atom.notifications.addError error.message, {detail: error.stack, dismissable: true}

  nextError: ->
    if not @messages
      @messages = @linter.views.getMessages()
    else
      @index++
    message = @messages.get(@index % @messages.length)
    return unless message?.filePath
    return unless message?.range
    atom.workspace.open(message.filePath).then ->
      atom.workspace.getActiveTextEditor().setCursorBufferPosition(message.range.start)

  previousError: ->
    if not @messages
      @messages = @linter.views.getMessages()
    else
      @index--
    message = @messages.get(@index % @messages.length)
    return unless message?.filePath
    return unless message?.range
    atom.workspace.open(message.filePath).then ->
      atom.workspace.getActiveTextEditor().setCursorBufferPosition(message.range.start)

  destroy: ->
    @messages = null
    @subscriptions.dispose()

module.exports = Commands
