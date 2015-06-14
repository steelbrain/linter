# This file is imported in views/panel

class Message extends HTMLElement
  initialize: (@message, @addPath)->

  attachedCallback: ->
    @appendChild Message.renderRibbon(@message.type)
    @appendChild Message.renderMessage(@message)
    @appendChild Message.renderLink(@message, @addPath) if @message.filePath

  @renderLink: (message, addPath)->
    displayFile = message.filePath
    atom.project.getPaths().forEach (path) =>
      return if message.filePath.indexOf(path) isnt 0 or displayFile isnt message.filePath # Avoid double replacing
      displayFile = message.filePath.substr( path.length + 1 ) # Remove the trailing slash as well
    El = document.createElement 'a'
    El.addEventListener 'click', ->
      Message.onClick message.filePath, message.range
    if message.range
      El.textContent = "at line #{message.range.start.row + 1} col #{message.range.start.column + 1} "
    if addPath
      El.textContent += "in #{displayFile}"
    El

  @renderRibbon: (type)->
    El = document.createElement 'span'
    El.classList.add 'badge'
    El.classList.add 'badge-flexible'
    El.classList.add "linter-highlight"
    El.classList.add type.toLowerCase()
    El.textContent = type
    El

  @renderMessage: (message)->
    El = document.createElement 'span'
    if message.html
      El.innerHTML = message.html
    else
      El.textContent = message.text
    El

  @onClick: (file, range)->
    atom.workspace.open(file).then ->
      return unless range
      atom.workspace.getActiveTextEditor().setCursorBufferPosition(range.start)

  @fromMessage: (message, showPaths)->
    MessageLine = new MessageElement()
    MessageLine.initialize(message, showPaths)
    MessageLine

module.exports = MessageElement = document.registerElement('linter-message', {prototype: Message.prototype})
module.exports.fromMessage = Message.fromMessage