# This file is imported in views/panel

class Message extends HTMLElement
  initialize: (@message, @addPath) ->

  attachedCallback: ->
    @appendChild Message.renderRibbon(@message.type)
    @appendChild Message.renderMessage(@message)
    @appendChild Message.renderLink(@message, @addPath) if @message.filePath

  @renderLink: (message, addPath) ->
    displayFile = message.filePath
    atom.project.getPaths().forEach (path) ->
      return if message.filePath.indexOf(path) isnt 0 or displayFile isnt message.filePath # Avoid double replacing
      displayFile = message.filePath.substr( path.length + 1 ) # Remove the trailing slash as well
    el = document.createElement 'a'
    el.addEventListener 'click', ->
      Message.onClick message.filePath, message.range
    if message.range
      el.textContent = "at line #{message.range.start.row + 1} col #{message.range.start.column + 1} "
    if addPath
      el.textContent += "in #{displayFile}"
    el

  @renderRibbon: (type) ->
    el = document.createElement 'span'
    el.classList.add 'badge'
    el.classList.add 'badge-flexible'
    el.classList.add "linter-highlight"
    for typeEntry in type.toLowerCase().split(' ')
      el.classList.add typeEntry
    el.textContent = type
    el

  @renderMessage: (message) ->
    el = document.createElement 'span'
    if message.html
      if typeof message.html is 'string'
        el.innerHTML = message.html
      else
        el.appendChild message.html
    else
      el.textContent = message.text
    el

  @onClick: (file, range) ->
    atom.workspace.open(file).then ->
      return unless range
      atom.workspace.getActiveTextEditor().setCursorBufferPosition(range.start)

  @fromMessage: (message, showPaths) ->
    MessageLine = new MessageElement()
    MessageLine.initialize(message, showPaths)
    MessageLine

module.exports = MessageElement = document.registerElement('linter-message', {prototype: Message.prototype})
module.exports.fromMessage = Message.fromMessage