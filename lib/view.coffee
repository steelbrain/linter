

{EventEmitter} = require 'events'
{Range} = require 'atom'

Bubble = require './view-bubble'

class LinterView extends EventEmitter
  constructor:(@Plus)->
    super()
    @decorations = []
    @root = document.createElement 'div'
    @root.id = 'linter-plus-panel'
    @bubble = null
  remove:->
    @bubble?.destroy()
    @removeDecorations()
    @removeErrors()
  removeDecorations:->
    @decorations.forEach (decoration)->
      try decoration.destroy()
  removeErrors:->
    while this.root.firstChild
      this.root.removeChild this.root.firstChild
  updateBubble:(Point)->
    @bubble?.destroy()
    return unless @Plus.Messages.length
    TextEditor = atom.workspace.getActiveTextEditor()
    ActiveFile = TextEditor.getPath()
    Found = false
    @Plus.Messages.forEach (Message)=>
      return if Found
      return unless Message.File is ActiveFile
      return unless Message.Position
      P = Message.Position
      LeRange = new Range([P[0][0]-1, P[0][1]-1], [P[1][0]-1, P[1][1]])
      return unless LeRange.containsPoint Point
      Marker = TextEditor.markBufferRange LeRange, {invalidate: 'never'}
      @bubble = TextEditor.decorateMarker Marker, type: 'overlay', item: new Bubble(@, Message)
      Found = true
  update:->
    @bubble?.destroy()
    @removeDecorations()
    @removeErrors()
    TextEditor = atom.workspace.getActiveTextEditor()
    ActiveFile = TextEditor.getPath()
    @Plus.Messages.forEach (Message)=>
      Entry = @messageLine Message
      @root.appendChild Entry

      return if Message.File isnt ActiveFile or not Message.Position
      P = Message.Position
      Marker = TextEditor.markBufferRange [[P[0][0]-1, P[0][1]-1], [P[1][0]-1, P[1][1]]], {invalidate: 'never'}
      @decorations.push TextEditor.decorateMarker Marker, type: 'line-number', class: 'line-number-' + Message.constructor.name.substr(4).toLowerCase()
      @decorations.push TextEditor.decorateMarker Marker, type: 'highlight', class: 'highlight-' + Message.constructor.name.substr(4).toLowerCase()
    @updateBubble(TextEditor.getCursors()[0].getBufferPosition())
  messageLine:(Message)->
    Entry = document.createElement 'div'

    Ribbon = document.createElement 'span'
    Ribbon.classList.add 'badge'
    Ribbon.classList.add 'badge-flexible'
    Ribbon.classList.add 'badge-' + Message.constructor.name.substr(4).toLowerCase()
    Ribbon.textContent = Message.constructor.name.substr(4)

    TheMessage = document.createElement('span')
    TheMessage.innerHTML = Message.Message

    if Message.File
      Message.DisplayFile = Message.File
      try
        atom.project.getPaths().forEach (Path)->
          return unless Message.File.indexOf(Path) is 0
          Message.DisplayFile = Message.File.substr( Path.length + 1 ) # Remove the trailing slash as well
          throw null
      File = document.createElement 'a'
      File.addEventListener 'click', @onclick.bind(null, Message.File, Message.Position)
      if Message.Position
        File.textContent = 'at line ' + Message.Position[0][0] + ' col ' + Message.Position[0][1] + ' in ' + Message.DisplayFile
      else
        File.textContent = 'in ' + Message.DisplayFile
    else
      File = null
    Entry.appendChild Ribbon
    Entry.appendChild TheMessage
    Entry.appendChild File if File
    return Entry
  onclick:(File, Position)->
    atom.workspace.open(File).then ->
      return unless Position
      atom.workspace.getActiveTextEditor().setCursorBufferPosition [Position[0][0]-1,Position[0][1]-1]
module.exports = LinterView