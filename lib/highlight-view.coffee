{Point, Range, View, $$} = require 'atom'

# Public: Represents a linter message code highlight
module.exports =
class HighLightView extends View

  @content: ->
    @div class: 'linter-highlight'

  regions: null

  # Public: Initialization of a highlight view to highlight a section of code
  #
  # options - Configuration parameters:
  #           :editorView - Atom.EditorView instance on which to highlight code
  #           :level  - the annotation error level ('error', 'warning')
  #           :range - The buffer range that the annotation should be placed on
  initialize: ({@editorView, @range, @level} = {}) ->
    @marker = @editorView.editor.buffer.markRange(@range)
    @marker = @editorView.editor.displayBuffer.getMarker(@marker.id)

    @regions = []
    @marker.on 'changed', => @render()
    @render()

  # Public: render the code highlight
  render: ->
    screenRange = @marker.getScreenRange()

    @removeRegions()
    @addClass(@level)
    if screenRange.start.isEqual(screenRange.end)
      screenRange.end = new Point(screenRange.end + 1, 0)
    rowSpan = screenRange.end.row - screenRange.start.row

    for rowIndex in [0..rowSpan]
      row = screenRange.start.row + rowIndex
      if rowIndex == 0
        columnStart = screenRange.start.column - 1
      else
        columnStart = 0
      if rowIndex == rowSpan
        columnEnd = screenRange.end.column
      else
        columnEnd = (@editorView.editor.displayBuffer.lineForRow row)
          .text.length - 1

      @appendRegion(
        {row: row, column: columnStart},
        {row: row, column: columnEnd}
      )

  # Private: create a higlight region for a single line of the range
  appendRegion: (start, end) ->
    try
      { lineHeight, charWidth } = @editorView
      css = @editorView.pixelPositionForScreenPosition(start)
      css.height = lineHeight
      css.width = @editorView.pixelPositionForScreenPosition(end).left -
          css.left

      region = ($$ -> @div class: 'region').css(css)
      if css.width > 0 or css.right == 0
        @append(region)
        @regions.push(region)

  # Private: clean up regions that have been rendered so we can adjust and show
  # new regions
  removeRegions: ->
    for region in @regions
      region.remove()
    @regions = []

  # Public: Remove this highlight view
  remove: ->
    @marker.destroy()
    super
