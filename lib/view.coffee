{EventEmitter} = require 'events'
{Range} = require 'atom'

Views = require './views'

class LinterView extends EventEmitter
  constructor: (@Linter) ->
    super()
    @Decorations = []
    @Messages = []
    @CountFile = 0
    @CountProject = 0
    @BarCurrent = null
    @BarProject = null
    @BarStatus = null
    @Bubble = null
    @Type = 'file'
    @Root = document.createElement 'div'
    @Root.id = 'linter-panel'

  remove: ->
    @Bubble?.destroy()
    @removeDecorations()
    @Root.innerHTML = ''

  removeDecorations: ->
    @Decorations.forEach (decoration) ->
      try decoration.destroy()

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
    @Messages = []
    @CountFile = 0
    @CountProject = 0
    @renderUpdateMessages(@Linter.MessagesProject.values())
    @renderUpdateMessages(@Linter.getActiveEditorLinter().Messages.values())
    if not @Messages.length
      @Linter.ViewPanel.hide() if @Linter.ViewPanel.isVisible()
      @remove()
      @updateTiles()
    else
      @update()
      @updateTiles()
      @Linter.ViewPanel.show() unless @Linter.ViewPanel.isVisible()
  renderUpdateMessages: (Values)->
    isProject = @Type is 'project'
    ActiveFile = @Linter.ActiveEditor.getPath()
    Value = Values.next()
    while not Value.done
      Value.value.forEach (Message)=>
        if (not (isProject or Message.File)) or Message.File is ActiveFile
          @Messages.push Message
          @CountFile = @CountFile + 1
        else if isProject
          @Messages.push Message
        @CountProject = @CountProject + 1
      Value = Values.next()
  update: ->
    @Bubble?.destroy()
    @removeDecorations()
    @Root.innerHTML = ''
    TextEditor = @Linter.ActiveEditor
    ActiveFile = TextEditor.getPath()
    @Messages.forEach (Message) =>
      Entry = @messageLine Message
      @Root.appendChild Entry

      return if Message.File isnt ActiveFile or not Message.Position
      P = Message.Position
      Marker = TextEditor.markBufferRange [[P[0][0] - 1, P[0][1] - 1], [P[1][0] - 1, P[1][1]]], {invalidate: 'never'}

      @Decorations.push TextEditor.decorateMarker(
        Marker, type: 'line-number', class: 'line-number-' + Message.Type.toLowerCase()
      )

      @Decorations.push TextEditor.decorateMarker(
        Marker, type: 'highlight', class: 'highlight-' + Message.Type.toLowerCase()
      )

    @updateBubble(TextEditor.getCursors()[0].getBufferPosition())

  updateTiles: ->
    @BarCurrent.Child.textContent = @CountFile.toString()
    @BarProject.Child.textContent = @CountProject.toString()
    if @Messages.length
      @BarStatus.Root.classList.remove 'linter-success'
      @BarStatus.Root.classList.add 'linter-error'
      @BarStatus.Child.classList.remove 'icon-check'
      @BarStatus.Child.classList.add 'icon-x'
      @BarStatus.Child.textContent = if @Messages.length is 1 then '1 Error' else @Messages.length + ' Errors'
    else
      @BarStatus.Root.classList.remove 'linter-error'
      @BarStatus.Root.classList.add 'linter-success'
      @BarStatus.Child.classList.remove 'icon-x'
      @BarStatus.Child.classList.add 'icon-check'
      @BarStatus.Child.textContent = 'No Errors'

  initTiles: ->
    @BarCurrent = Views.currentFile(this)
    @BarProject = Views.wholeProject(this)
    @BarStatus = Views.status()
    @BarStatus.Child.classList.add 'icon-check'
    @BarStatus.Child.textContent = 'No Errors'
    @Linter.StatusBar.addLeftTile
      item: @BarCurrent.Root,
      priority: -1001
    @Linter.StatusBar.addLeftTile
      item: @BarProject.Root,
      priority: -1000
    @Linter.StatusBar.addLeftTile
      item: @BarStatus.Root
      priority: -999

  messageLine: (Message) ->
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
          'at line ' + Message.Position[0][0] + ' col ' + Message.Position[0][1] + ' in ' + Message.DisplayFile
      else
        File.textContent = 'in ' + Message.DisplayFile
    else
      File = null

    Entry.appendChild Ribbon
    Entry.appendChild TheMessage
    Entry.appendChild File if File
    return Entry

  onclick: (File, Position) ->
    atom.workspace.open(File).then =>
      return unless Position
      @Linter.ActiveEditor.setCursorBufferPosition [Position[0][0] - 1, Position[0][1] - 1]

module.exports = LinterView
