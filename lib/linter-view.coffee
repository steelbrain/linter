class LinterView
  constructor: (@Linter) ->
    @Messages = []

  render: ->
    return @hide([]) unless @Linter.ActiveEditor # When we don't have any editor
    return @hide([]) unless @Linter.ActiveEditor.getPath?() # When we have an invalid text editor
    @Messages = @renderMessages(@Linter.MessagesProject.values())
    ActiveLinter = @Linter.getActiveEditorLinter()
    if ActiveLinter
      @Messages.concat @renderMessages(ActiveLinter.Messages.values())
    if not @Messages.length
      @hide @Messages
    else
      @Linter.Panel.render @Messages
      @Linter.PanelModal.show() unless @Linter.PanelModal.isVisible()
    @Linter.Bubble.update @Linter.ActiveEditor.getCursorBufferPosition()
    @Linter.Bottom.update @Messages

  hide: (Messages) ->
    @Linter.PanelModal.hide() if @Linter.PanelModal.isVisible()
    @Linter.Panel.render Messages

  renderMessages: (Values) ->
    isProject = @Linter.Panel.Type is 'project'
    ActiveFile = @Linter.ActiveEditor.getPath()
    Value = Values.next()
    ToReturn = []
    while not Value.done
      Value.value.forEach (Message) =>
        if (not Message.File and not isProject) or Message.File is ActiveFile
          Message.CurrentFile = true
        else
          Message.CurrentFile = false
        ToReturn.push Message
        @CountProject = @CountProject + 1
      Value = Values.next()
    ToReturn

  messageLine: (Message, addPath = true) ->
    Entry = document.createElement 'div'

    Ribbon = document.createElement 'span'
    Ribbon.classList.add 'badge'
    Ribbon.classList.add 'badge-flexible'
    Ribbon.classList.add 'badge-' + Message.Type.toLowerCase()
    Ribbon.textContent = Message.Type

    TheMessage = document.createElement('span')
    if Message.HTML and Message.HTML.length
      TheMessage.innerHTML = Message.HTML
    else
      TheMessage.textContent = Message.Message

    if Message.File
      Message.DisplayFile = Message.File
      try
        atom.project.getPaths().forEach (Path) ->
          return unless Message.File.indexOf(Path) is 0
          Message.DisplayFile = Message.File.substr( Path.length + 1 ) # Remove the trailing slash as well
          throw null
      File = document.createElement 'a'
      File.addEventListener 'click', @onclick.bind(null, Message.File, Message.Position)
      if Message.Position
        File.textContent =
          'at line ' + Message.Position[0][0] + ' col ' + Message.Position[0][1] + ' '
      if addPath
        File.textContent += 'in ' + Message.DisplayFile
    else
      File = null

    Entry.appendChild Ribbon
    Entry.appendChild TheMessage
    Entry.appendChild File if File
    return Entry

  onclick: (File, Position) ->
    atom.workspace.open(File).then ->
      return unless Position
      atom.workspace.getActiveTextEditor().setCursorBufferPosition [Position[0][0] - 1, Position[0][1] - 1]

module.exports = LinterView
