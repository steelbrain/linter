# This file is imported in views/panel

class Message extends HTMLElement
  initialize: (@message, @addPath)->

  attachedCallback: ->
    # The ribbon
    ribbon = document.createElement 'span'
    ribbon.classList.add 'badge'
    ribbon.classList.add 'badge-flexible'
    ribbon.classList.add "badge-#{@message.type.toLowerCase()}"
    ribbon.textContent = @message.type

    # The message
    theMessage = document.createElement('span')
    if @message.html and @message.html.length
      theMessage.innerHTML = message.html
    else
      theMessage.textContent = @message.message

    # The link
    if @message.file
      @message.displayFile = @message.file
      try
        atom.project.getPaths().forEach (path) =>
          return unless @message.file.indexOf(path) is 0
          @message.displayFile = @message.file.substr( path.length + 1 ) # Remove the trailing slash as well
          throw null
      file = document.createElement 'a'
      file.addEventListener 'click', @onClick.bind(this, @message.file, @message.position)
      if @message.position
        file.textContent =
          'at line ' + @message.position[0][0] + ' col ' + @message.position[0][1] + ' '
      if @addPath
        file.textContent += 'in ' + @message.displayFile
    else
      file = null
    @appendChild ribbon
    @appendChild theMessage
    @appendChild file if file
  onClick: ->
    atom.workspace.open(@message.file).then =>
      return unless @message.position
      atom.workspace.getActiveTextEditor().setCursorBufferPosition(
        [@message.position[0][0] - 1, @message.position[0][1] - 1]
      )

module.exports = Message = document.registerElement('linter-message', {prototype: Message.prototype})