# This file is imported in views/panel

class Message extends HTMLElement
  initialize: (@message, @addPath)->

  attachedCallback: ->

    # The link
    if @message.file
      @message.displayFile = @message.file
      try
        atom.project.getPaths().forEach (path) =>
          return unless @message.file.indexOf(path) is 0
          @message.displayFile = @message.file.substr( path.length + 1 ) # Remove the trailing slash as well
          throw null
      file = document.createElement 'a'
      file.addEventListener 'click', Message.onClick.bind(null, @message.file, @message.position)
      if @message.position
        file.textContent =
          'at line ' + @message.position[0][0] + ' col ' + @message.position[0][1] + ' '
      if @addPath
        file.textContent += 'in ' + @message.displayFile
    else
      file = null
    @appendChild Message.renderRibbon(@message.type)
    @appendChild Message.renderMessage(@message)
    @appendChild file if file

  @renderRibbon: (Type)->
    El = document.createElement 'span'
    El.classList.add 'badge'
    El.classList.add 'badge-flexible'
    El.classList.add "badge-#{Type.toLowerCase()}"
    El.textContent = Type
    El

  @renderMessage: (message)->
    El = document.createElement 'span'
    if message.html
      El.innerHTML = message.html
    else
      El.textContent = message.message
    El

  @onClick: (file, position)->
    atom.workspace.open(file).then ->
      return unless position
      atom.workspace.getActiveTextEditor().setCursorBufferPosition(
        [position[0][0] - 1, position[0][1] - 1]
      )

module.exports = document.registerElement('linter-message', {prototype: Message.prototype})