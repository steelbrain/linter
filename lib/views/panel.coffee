class PanelView extends HTMLElement
  initialize:(@linter)->
    @id = 'linter-panel'
    @decorations = []
  removeDecorations: ->
    return unless @decorations.length
    @decorations.forEach (decoration) ->
      try decoration.destroy()
    @decorations = []
  render: (messages)->
    @removeDecorations()
    @innerHTML = ''
    messages.forEach (message)=>
      return unless message.currentFile # A custom property added while creating arrays of them
      return unless message.position
      return if @type is 'file' and (not message.currentFile)
      p = message.position
      range = [[p[0][0] - 1, p[0][1] - 1], [p[1][0] - 1, p[1][1]]]
      marker = @linter.activeEditor.markBufferRange range, {invalidate: 'never'}
      @decorations.push @linter.activeEditor.decorateMarker(
        marker, type: 'line-number', class: 'line-number-' + message.type.toLowerCase()
      )
      @decorations.push @linter.activeEditor.decorateMarker(
        marker, type: 'highlight', class: 'highlight-' + message.type.toLowerCase()
      )
      @appendChild @linter.view.messageLine message, @linter.views.type is 'project'

module.exports = PanelView = document.registerElement('linter-panel-view', {prototype: PanelView.prototype})