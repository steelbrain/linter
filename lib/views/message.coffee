class Message extends HTMLElement
  initialize: (@message, @options) ->

  attachedCallback: ->
    @appendChild Message.renderRibbon(@message)
    @appendChild Message.renderMessage(@message, @options)
    @appendChild Message.renderLink(@message, @options) if @message.filePath
    @appendChild Message.renderAcceptReplacement(@message) if @message.replacement

  @renderLink: (message, {addPath}) ->
    displayFile = message.filePath
    atom.project.getPaths().forEach (path) ->
      return if message.filePath.indexOf(path) isnt 0 or displayFile isnt message.filePath # Avoid double replacing
      displayFile = message.filePath.substr( path.length + 1 ) # Remove the trailing slash as well
    el = document.createElement 'a'
    el.classList.add 'linter-message-item'
    el.addEventListener 'click', ->
      Message.onClick message.filePath, message.range
    if message.range
      el.textContent = "at line #{message.range.start.row + 1} col #{message.range.start.column + 1} "
    if addPath
      el.textContent += "in #{displayFile}"
    el

  @renderAcceptReplacement: (message) ->
    el = document.createElement 'span'
    el.classList.add 'linter-message-item'

    dash = document.createElement 'span'
    dash.textContent = ' - '
    el.appendChild dash

    link = document.createElement 'a'
    link.addEventListener 'click', ->
      if message.range
        atom.workspace.open(message.filePath).then ->
          editor = atom.workspace.getActiveTextEditor()
          editor.setTextInBufferRange(message.range, "")
          editor.insertText(message.replacement)
    link.textContent = 'Accept!'
    el.appendChild link
    el

  @renderRibbon: (message) ->
    el = document.createElement 'span'
    el.classList.add 'linter-message-item'
    el.classList.add 'badge'
    el.classList.add 'badge-flexible'
    el.classList.add "linter-highlight"
    el.classList.add message.class
    el.textContent = message.type
    el

  @renderMessage: (message, {cloneNode}) ->
    el = document.createElement 'span'
    el.classList.add 'linter-message-item'
    if message.html
      if typeof message.html is 'string'
        el.innerHTML = message.html
      else
        if cloneNode
          el.appendChild message.html.cloneNode(true)
        else
          el.appendChild message.html
    else if message.multiline
      el.appendChild Message.processMultiLine message.text
    else
      el.textContent = message.text
    el

  @processMultiLine: (text) ->
    container = document.createElement 'linter-multiline-message'
    for line in @text.split(/\n/)
      if line
        el = document.createElement 'linter-message-line'
        el.textContent = line
        container.appendChild el
    container

  @onClick: (file, range) ->
    atom.workspace.open(file).then ->
      return unless range
      atom.workspace.getActiveTextEditor().setCursorBufferPosition(range.start)

  @fromMessage: (message, options = {}) ->
    MessageLine = new MessageElement()
    MessageLine.initialize(message, options)
    MessageLine

module.exports = MessageElement = document.registerElement('linter-message', {prototype: Message.prototype})
module.exports.fromMessage = Message.fromMessage
