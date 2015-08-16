{CompositeDisposable} = require 'atom'

class Commands
  constructor: (@linter) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'linter:next-error': => @nextError()
      'linter:previous-error': => @previousError()
      'linter:toggle': => @toggleLinter()
      'linter:togglePanel': => @togglePanel()
      'linter:set-bubble-transparent': => @setBubbleTransparent()
      'linter:expand-multiline-messages': => @expandMultilineMessages()
      'linter:lint': => @lint()

    # Default values
    @index = null

  togglePanel: ->
    @linter.views.panel.panelVisibility = not @linter.views.panel.panelVisibility

  toggleLinter: ->
    activeEditor = atom.workspace.getActiveTextEditor()
    return unless activeEditor
    editorLinter = @linter.getEditorLinter(activeEditor)
    if editorLinter
      editorLinter.destroy()
    else
      @linter.createEditorLinter(activeEditor)


  setBubbleTransparent: ->
    bubble = document.getElementById('linter-inline')
    if bubble
      bubble.classList.add 'transparent'
      document.addEventListener 'keyup', @setBubbleOpaque
      window.addEventListener 'blur', @setBubbleOpaque

  setBubbleOpaque: ->
    bubble = document.getElementById('linter-inline')
    if bubble
      bubble.classList.remove 'transparent'
    document.removeEventListener 'keyup', @setBubbleOpaque
    window.removeEventListener 'blur', @setBubbleOpaque

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
    catch error
      atom.notifications.addError error.message, {detail: error.stack, dismissable: true}

  getMessage: (index) ->
    messages = @linter.views.messages
    # Use the dividend independent modulo so that the index stays inside the
    # array's bounds, even when negative.
    # That way the index can be ++ an -- without caring about the array bounds.
    messages[index %% messages.length]

  nextError: ->
    if @index?
      @index++
    else
      @index = 0
    message = @getMessage(@index)
    return unless message?.filePath
    return unless message?.range
    atom.workspace.open(message.filePath).then ->
      atom.workspace.getActiveTextEditor().setCursorBufferPosition(message.range.start)

  previousError: ->
    if @index?
      @index--
    else
      @index = 0
    message = @getMessage(@index)
    return unless message?.filePath
    return unless message?.range
    atom.workspace.open(message.filePath).then ->
      atom.workspace.getActiveTextEditor().setCursorBufferPosition(message.range.start)

  dispose: ->
    @messages = null
    @subscriptions.dispose()

module.exports = Commands
