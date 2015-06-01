class LinterView
  constructor: (@linter) ->
    @messages = []

  render: ->
    return @hide([]) unless @linter.activeEditor # When we don't have any editor
    return @hide([]) unless @linter.activeEditor.getPath?() # When we have an invalid text editor

    activeLinter = @linter.getActiveEditorLinter()

    messages = @renderMessages(@linter.messagesProject.values())
    messages = messages.concat(@renderMessages(activeLinter.messages.values())) if activeLinter
    @messages = messages

    if @messages.length
      @linter.panel.render @messages
      @linter.panelModal.show() unless @linter.panelModal.isVisible()
    else
      @hide @messages

    @linter.bubble.update @linter.activeEditor.getCursorBufferPosition()
    @linter.bottom.update @messages

  hide: (messages) ->
    @linter.panelModal.hide() if @linter.panelModal.isVisible()
    @linter.panel.render messages

  renderMessages: (values) ->
    isProject = @linter.panel.type is 'project'
    activeFile = @linter.activeEditor.getPath()
    value = values.next()
    toReturn = []
    while not value.done
      value.value.forEach (message) =>
        if (not message.File and not isProject) or message.File is activeFile
          message.currentFile = true
        else
          message.currentFile = false
        toReturn.push message
        @countProject = @countProject + 1
      value = values.next()
    toReturn

  messageLine: (message, addPath = true) ->
    entry = document.createElement 'div'

    ribbon = document.createElement 'span'
    ribbon.classList.add 'badge'
    ribbon.classList.add 'badge-flexible'
    ribbon.classList.add 'badge-' + message.Type.toLowerCase()
    ribbon.textContent = message.Type

    theMessage = document.createElement('span')
    if message.HTML and message.HTML.length
      theMessage.innerHTML = message.HTML
    else
      theMessage.textContent = message.Message

    if message.File
      message.displayFile = message.File
      try
        atom.project.getPaths().forEach (path) ->
          return unless message.File.indexOf(path) is 0
          message.displayFile = message.File.substr( path.length + 1 ) # Remove the trailing slash as well
          throw null
      file = document.createElement 'a'
      file.addEventListener 'click', @onclick.bind(null, message.File, message.Position)
      if message.Position
        file.textContent =
          'at line ' + message.Position[0][0] + ' col ' + message.Position[0][1] + ' '
      if addPath
        file.textContent += 'in ' + message.displayFile
    else
      file = null

    entry.appendChild ribbon
    entry.appendChild theMessage
    entry.appendChild file if file
    return entry

  onclick: (file, position) ->
    atom.workspace.open(file).then ->
      return unless position
      atom.workspace.getActiveTextEditor().setCursorBufferPosition [position[0][0] - 1, position[0][1] - 1]

module.exports = LinterView
