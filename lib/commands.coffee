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

  togglePanel: ->
    atom.config.set('linter.showErrorPanel', not atom.config.get('linter.showErrorPanel'))

  toggleLinter: ->
    activeEditor = atom.workspace.getActiveTextEditor()
    return unless activeEditor
    editorLinter = @linter.getEditorLinter(activeEditor)
    if editorLinter
      editorLinter.dispose()
    else
      @linter.createEditorLinter(activeEditor)
      @lint()


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

  nextError: ->

    activeTextEditor = atom.workspace.getActiveTextEditor()
    if activeTextEditor?
      {row, column} = activeTextEditor.getCursorBufferPosition()
      thisFile = @linter.views.messages.filter((m) -> m.currentFile )

      message = do ->
        for m in thisFile when m.range?
          {start} = m.range
          if start.row > row
            return m
          if start.row is row and start.column > column
            return m

      # loop around if necessary
      message ?= thisFile[0]
    # Move on to another file if there's nothing here
    message ?= @linter.views.messages[0]

    return unless message?.filePath
    return unless message?.range
    atom.workspace.open(message.filePath).then ->
      atom.workspace.getActiveTextEditor().setCursorBufferPosition(message.range.start)

  previousError: ->
    activeTextEditor = atom.workspace.getActiveTextEditor()
    if activeTextEditor?
      {row, column} = activeTextEditor.getCursorBufferPosition()
      thisFile = @linter.views.messages.filter((m) -> m.currentFile )

      message = undefined
      for m in thisFile when m.range?
        {start} = m.range
        if start.row < row
          message = m
        if start.row is row and start.column < column
          message = m

      # loop around if necessary
      message ?= thisFile[-1..]?[0]
    # Move on to another file if there's nothing here
    message ?= @linter.views.messages[-1..]?[0]


    return unless message?.filePath
    return unless message?.range
    atom.workspace.open(message.filePath).then ->
      atom.workspace.getActiveTextEditor().setCursorBufferPosition(message.range.start)

  dispose: ->
    @messages = null
    @subscriptions.dispose()

module.exports = Commands
