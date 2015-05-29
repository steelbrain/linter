{EventEmitter} = require 'events'
{Range} = require 'atom'

Bubble = require './view-bubble'
LeftTile = require './view-left-tile'

class LinterView extends EventEmitter
  constructor: (@Linter) ->
    super()
    @decorations = []
    @root = document.createElement 'div'
    @root.id = 'linter-panel'
    @bubble = null

  remove: ->
    @bubble?.destroy()
    @removeDecorations()
    @removeErrors()

  removeDecorations: ->
    @decorations.forEach (decoration) ->
      try decoration.destroy()

  removeErrors: ->
    while this.root.firstChild
      this.root.removeChild this.root.firstChild

  updateBubble: (Point) ->
    @bubble?.destroy()
    return unless @Linter.Messages.length
    TextEditor = @Linter.ActiveEditor
    ActiveFile = TextEditor.getPath()
    Found = false
    @Linter.Messages.forEach (Message) =>
      return if Found
      return unless Message.File is ActiveFile
      return unless Message.Position
      P = Message.Position
      LeRange = new Range([P[0][0] - 1, P[0][1] - 1], [P[1][0] - 1, P[1][1]])
      return unless LeRange.containsPoint Point
      Marker = TextEditor.markBufferRange LeRange, {invalidate: 'never'}
      @bubble = TextEditor.decorateMarker Marker, type: 'overlay', item: new Bubble(@, Message)
      Found = true

  update: ->
    @bubble?.destroy()
    @removeDecorations()
    @removeErrors()
    TextEditor = @Linter.ActiveEditor
    ActiveFile = TextEditor.getPath()
    @Linter.Messages.forEach (Message) =>
      Entry = @messageLine Message
      @root.appendChild Entry

      return if Message.File isnt ActiveFile or not Message.Position
      P = Message.Position
      Marker = TextEditor.markBufferRange [[P[0][0] - 1, P[0][1] - 1], [P[1][0] - 1, P[1][1]]], {invalidate: 'never'}

      @decorations.push TextEditor.decorateMarker(
        Marker, type: 'line-number', class: 'line-number-' + Message.Type.toLowerCase()
      )

      @decorations.push TextEditor.decorateMarker(
        Marker, type: 'highlight', class: 'highlight-' + Message.Type.toLowerCase()
      )

    @updateBubble(TextEditor.getCursors()[0].getBufferPosition())

  updateLeftTile: (nbMessages) ->
    # Remove old tile
    @leftTile?.destroy?()
    @leftTile = null

    # Create new tile with `@Linter.Messages` length
    el = new LeftTile(nbMessages)
    @leftTile = @Linter.StatusBar.addLeftTile
      item: el
      priority: -100

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
