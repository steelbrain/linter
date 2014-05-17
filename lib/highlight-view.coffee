{Point, Range, View, $$} = require 'atom'

module.exports =
class HighLightView extends View

  @content: ->
    @div class: 'linter-highlight'

  regions: null

  initialize: ({@editorView, @range, @level} = {}) ->
    @marker = @editorView.editor.buffer.markRange(@range)
    @marker = @editorView.editor.displayBuffer.getMarker(@marker.id)

    @regions = []
    @marker.on 'changed', => @render()
    @render()

  render: ->
    newRange = @marker.getScreenRange()
    @range.start = newRange.start
    @range.end = newRange.end

    @removeRegions()
    @addClass(@level)
    if @range.start.isEqual(@range.end)
      @range.end = new Point(@range.end + 1, 0)
    rowSpan = @range.end.row - @range.start.row

    for rowIndex in [0..rowSpan]
      row = @range.start.row + rowIndex
      if rowIndex == 0
        columnStart = @range.start.column
      else
        columnStart = 0
      if rowIndex == rowSpan
        columnEnd = @range.end.column
      else
        columnEnd = (@editorView.editor.displayBuffer.lineForRow row)
          .text.length - 1

      @appendRegion(
        {row: row, column: columnStart},
        {row: row, column: columnEnd}
      )

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

  removeRegions: ->
    for region in @regions
      region.remove()
    @regions = []

  getCenterPixelPosition: ->
    { start, end } = @range
    startRow = start.row
    endRow = end.row
    endRow-- if end.column == 0
    @editorView.pixelPositionForScreenPosition(
      [((startRow + endRow + 1) / 2), start.column]
    )

  remove: ->
    @marker.destroy()
    super
