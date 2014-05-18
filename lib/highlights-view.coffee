{Point, Range, View, $$} = require 'atom'
HighLightView = require './highlight-view'

# Public: Represents a collection of code highlights
module.exports =
class HighLightsView extends View

  @content: ->
    @div class: 'linter-highlights'

  highlights: []

  # Public: Initialization of a highlights view for rendering a set of code
  # highlight messages
  #
  # editorView - Atom.EditorView instance on which to highlight code
  initialize: (@editorView) ->
    @highlights = []

  # Public: Render messages on this highlights view
  #
  # messages - An array of messages to annotate:
  #           :level  - the annotation error level ('error', 'warning')
  #           :range - The buffer range that the annotation should be placed
  setHighlights: (messages) ->
    @removeHighlights()
    for message in messages
      highlightView = new HighLightView(
        range: message.range,
        editorView: @editorView,
        level: message.level)
      @editorView.underlayer.append(highlightView)
      @highlights.push(highlightView)

  # Public: Remove highlights from the view
  removeHighlights: ->
    for highlight in @highlights
      highlight.remove()
    @highlights = []
