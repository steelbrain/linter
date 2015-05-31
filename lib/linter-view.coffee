{Range} = require 'atom'

Views = require './views'

class LinterView
  constructor: (@Linter) ->
    @MessagesCurrentFile = []
    @Messages = []
    @Bubble = null
    @Type = 'file'

  remove: ->
    @Bubble?.destroy()

  updateBubble: (Point) ->
    @Bubble?.destroy()
    return unless @Messages.length
    TextEditor = @Linter.ActiveEditor
    ActiveFile = TextEditor.getPath()
    Found = false
    @Messages.forEach (Message) =>
      return if Found
      return unless Message.File is ActiveFile
      return unless Message.Position
      P = Message.Position
      LeRange = new Range([P[0][0] - 1, P[0][1] - 1], [P[1][0] - 1, P[1][1]])
      return unless LeRange.containsPoint Point
      Marker = TextEditor.markBufferRange LeRange, {invalidate: 'never'}
      @Bubble = TextEditor.decorateMarker Marker, type: 'overlay', item: Views.bubble(@, Message)
      Found = true
  render: ->
    return unless @Linter.ActiveEditor # When we don't have any editor
    return @Linter.Panel.render([])
    @Messages = []
    @renderUpdateMessages(@Linter.MessagesProject.values())
    @renderUpdateMessages(@Linter.getActiveEditorLinter().Messages.values())
    if not @Messages.length
      @Linter.ViewPanel.hide() if @Linter.ViewPanel.isVisible()
    else
      @Linter.ViewPanel.show() unless @Linter.ViewPanel.isVisible()
  renderUpdateMessages: (Values) ->
    isProject = @Type is 'project'
    ActiveFile = @Linter.ActiveEditor.getPath()
    Value = Values.next()
    while not Value.done
      Value.value.forEach (Message) =>
        if (not (isProject or Message.File)) or Message.File is ActiveFile
          @Messages.push Message
          @MessagesCurrentFile.push Message
          @CountFile = @CountFile + 1
        else if isProject
          @Messages.push Message
        @CountProject = @CountProject + 1
      Value = Values.next()

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
