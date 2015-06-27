class MessageLine extends HTMLElement
  setText: (@textContent) -> @

LineElement =
  document.registerElement('message-line', prototype: MessageLine.prototype)

class Multiline extends HTMLElement
  attachedCallback: ->
    @tabIndex = 0
    for line in @text.split(/\n/)
      if line
        @appendChild new LineElement().setText line

  setText: (@text) -> @

  @fromText: (text) ->
    new MultilineElement().setText text

module.exports = MultilineElement =
  document.registerElement('linter-multiline-message', prototype: Multiline.prototype)
module.exports.fromText = Multiline.fromText
