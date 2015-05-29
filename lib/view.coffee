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
    @removeErrors()

  removeDecorations: ->
    @Decorations.forEach (decoration) ->
      try decoration.destroy()

  removeErrors: ->
    while this.Root.firstChild
      this.Root.removeChild this.Root.firstChild

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
    @Messages = []
    @CountFile = 0
    @CountProject = 0
    Values = @Linter.MessagesProject.values()
    Value = Values.next()
    while not Value.done
      @Messages = @Messages.concat Value.value if @Type is 'project'
      @CountProject += Value.value.length
      Value = Values.next()
    Values = @Linter.getActiveEditorLinter().Messages.values()
    Value = Values.next()
    while not Value.done
      @Messages = @Messages.concat Value.value
      @CountFile += Value.value.length
      Value = Values.next()
    if not @Messages.length
      @Linter.ViewPanel.hide() if @Linter.ViewPanel.isVisible()
      @remove()
    else
      @update()
      @Linter.ViewPanel.show() unless @Linter.ViewPanel.isVisible()
  update: ->
    @Bubble?.destroy()
    @removeDecorations()
    @removeErrors()
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

  initTiles: ->
    @BarCurrent = Views.currentFile(this)
    @BarProject = Views.wholeProject(this)
    @BarStatus = Views.status()
    @BarStatus.Child.classList.add 'icon-check'
    @BarStatus.Child.textContent = 'No Errors'
    @Linter.StatusBar.addLeftTile
      item: @BarCurrent,
      priority: -1001
    @Linter.StatusBar.addLeftTile
      item: @BarProject,
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
