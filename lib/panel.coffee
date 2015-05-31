class Panel
  constructor: (@Linter)->
    @Decorations = []
    @Type = 'file'
    @View = null
  removeDecorations: ->
    return unless @Decorations.length
    @Decorations.forEach (decoration) ->
      try decoration.destroy()
    @Decorations = []
  render: (Messages)->
    @removeDecorations()
    if not Messages.length
      return @View.innerHTML = ''
    Messages.forEach (Message) =>
      return unless Message.CurrentFile # A custom property added while creating arrays of them
      return unless Message.Position
      return if @Type is 'file' and (not Message.CurrentFile)
      P = Message.Position
      Marker = @Linter.ActiveEditor.markBufferRange [[P[0][0] - 1, P[0][1] - 1], [P[1][0] - 1, P[1][1]]], {invalidate: 'never'}

      @Decorations.push @Linter.ActiveEditor.decorateMarker(
        Marker, type: 'line-number', class: 'line-number-' + Message.Type.toLowerCase()
      )

      @Decorations.push @Linter.ActiveEditor.decorateMarker(
        Marker, type: 'highlight', class: 'highlight-' + Message.Type.toLowerCase()
      )
    @View.render Messages
module.exports = Panel