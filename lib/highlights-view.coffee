{Point, Range, View, $$} = require 'atom'

# Public: Represents a collection of code highlights
module.exports =
class HighLightsView

  # Public: Initialization of a highlights view for rendering a set of code
  # highlight messages
  #
  # editor - Atom.Editor instance on which to highlight code
  constructor: (editor) ->
    @editor = editor
    @markers = null

  # Public: Render messages on this highlights view
  #
  # messages - An array of messages to annotate:
  #           :level  - the annotation error level ('error', 'warning')
  #           :range - The buffer range that the annotation should be placed
  setHighlights: (messages) ->
    @removeHighlights()

    @markers ?= []
    for message in messages
      klass = if message.level == 'error'
        'linter-error'
      else if message.level == 'warning'
        'linter-warning'
      return unless klass?  # skip other messages

      marker = @editor.markBufferRange message.range, invalidate: 'never'
      @editor.decorateMarker marker, type: 'highlight', class: klass
      @markers.push marker

  # Public: Remove highlights from the view
  removeHighlights: ->
    return unless @markers
    m.destroy() for m in @markers
    @markers = null
