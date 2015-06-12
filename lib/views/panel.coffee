Message = require './message'

class PanelView extends HTMLElement
  initialize:(@linter) ->
    @id = 'linter-panel'
    @decorations = []
  removeDecorations: ->
    return unless @decorations.length
    @decorations.forEach (decoration) ->
      try decoration.destroy()
    @decorations = []

  update: ->
    if @linter.views.messages.length
      @render @linter.views.messages
      @linter.views.panelVisibility(true)
    else
      @hide()

  hide: ->
    @removeDecorations()
    @linter.views.bubble?.remove()
    @innerHTML = ''
    @linter.views.panelVisibility(false)
  render: (messages) ->
    @removeDecorations()
    @innerHTML = ''
    messages.forEach (message) =>
      if @linter.views.scope is 'file'
        return unless message.currentFile
      if message.currentFile and message.position
        p = message.position
        range = [[p[0][0] - 1, p[0][1] - 1], [p[1][0] - 1, p[1][1]]]
        marker = @linter.activeEditor.markBufferRange range, {invalidate: 'never'}
        @decorations.push @linter.activeEditor.decorateMarker(
          marker, type: 'line-number', class: "line-number-#{message.type.toLowerCase()}"
        )
        @decorations.push @linter.activeEditor.decorateMarker(
          marker, type: 'highlight', class: "highlight-#{message.type.toLowerCase()}"
        )
      MessageLine = new Message()
      MessageLine.initialize(message, @linter.views.scope is 'project')
      @appendChild MessageLine

module.exports = PanelView = document.registerElement('linter-panel-view', {prototype: PanelView.prototype})