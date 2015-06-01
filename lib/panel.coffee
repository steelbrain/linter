class Panel
  constructor: (@linter) ->
    @decorations = []
    @type = 'file'
    @view = null

  removeDecorations: ->
    return unless @decorations.length
    @decorations.forEach (decoration) ->
      try decoration.destroy()
    @decorations = []

  render: (messages) ->
    @removeDecorations()
    if not messages.length
      return @view.innerHTML = ''
    messages.forEach (message) =>
      return unless message.currentFile # A custom property added while creating arrays of them
      return unless message.Position
      return if @type is 'file' and (not message.currentFile)
      p = message.Position
      range = [[p[0][0] - 1, p[0][1] - 1], [p[1][0] - 1, p[1][1]]]
      marker = @linter.activeEditor.markBufferRange range, {invalidate: 'never'}

      @decorations.push @linter.activeEditor.decorateMarker(
        marker, type: 'line-number', class: 'line-number-' + message.Type.toLowerCase()
      )

      @decorations.push @linter.activeEditor.decorateMarker(
        marker, type: 'highlight', class: 'highlight-' + message.Type.toLowerCase()
      )
    @view.render messages

module.exports = Panel
