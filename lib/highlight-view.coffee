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

    if rowSpan == 0
      @appendRegion(1, @range.start, @range.end)
    else
      @appendRegion(1, @range.start, null)
      if rowSpan > 1
        @appendRegion(rowSpan - 1, { row: @range.start.row + 1, column: 0}, null)
      @appendRegion(1, { row: @range.end.row, column: 0 }, @range.end)

  appendRegion: (rows, start, end) ->
    try
      { lineHeight, charWidth } = @editorView
      css = @editorView.pixelPositionForScreenPosition(start)
      css.height = lineHeight * rows
      if end and end.row <= @editorView.editor.getLineCount()
        css.width = @editorView.pixelPositionForScreenPosition(end).left - css.left
      else
        css.right = 0

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
    @editorView.pixelPositionForScreenPosition([((startRow + endRow + 1) / 2), start.column])

  remove: ->
    @marker.destroy()
    super
