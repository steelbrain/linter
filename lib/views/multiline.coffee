class Multiline extends HTMLElement
  attachedCallback: ->
    @tabIndex = 0
    for line in @text.split(/\n/)
      if line
        el = document.createElement 'linter-message-line'
        el.textContent = line
        @appendChild el

  setText: (@text) -> @

  @fromText: (text) ->
    new MultilineElement().setText text

module.exports = MultilineElement =
  document.registerElement('linter-multiline-message', prototype: Multiline.prototype)
module.exports.fromText = Multiline.fromText
