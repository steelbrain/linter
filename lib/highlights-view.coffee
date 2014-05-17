{Point, Range, View, $$} = require 'atom'
HighLightView = require './highlight-view'

module.exports =
class HighLightsView extends View

  @content: ->
    @div class: 'linter-highlights'

  highlights: []

  initialize: (@editorView) ->
    @highlights = []

  setHighlights: (messages) ->
    @removeHighlights()
    for message in messages
      message.range ?= new Range([parseInt(message.line) - 1, 0],[parseInt(message.line), 0])
      highlightView = new HighLightView(range: message.range, editorView: @editorView, level: message.level)
      @editorView.underlayer.append(highlightView)
      @highlights.push(highlightView)


  removeHighlights: ->
    for highlight in @highlights
      highlight.remove()
    @highlights = []
