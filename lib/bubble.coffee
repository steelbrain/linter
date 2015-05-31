{Range} = require 'atom'
BubbleView = require './bubble-view'

class Bubble
  constructor: (@Linter) ->
    @Bubble = null

  update: (Point) ->
    @remove()
    return unless @Linter.View.Messages.length
    TextEditor = @Linter.ActiveEditor
    Found = false
    @Linter.View.Messages.forEach (Message) =>
      return if Found
      return unless Message.CurrentFile
      return unless Message.Position
      P = Message.Position
      ErrorRange = new Range([P[0][0] - 1, P[0][1] - 1], [P[1][0] - 1, P[1][1]])
      return unless ErrorRange.containsPoint Point
      Marker = TextEditor.markBufferRange ErrorRange, {invalidate: 'never'}
      @Bubble = TextEditor.decorateMarker Marker, type: 'overlay', item: BubbleView(@Linter, Message)
      Found = true

  remove: ->
    @Bubble?.destroy()

module.exports = Bubble
