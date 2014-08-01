# Gutter view for the plugin

# Public: Represents a linter gutter annotation view
class GutterView

  # Public: Create a linter gutter view for annotating with an Atom.Editor
  # instance
  #
  # editorView  - Atom.EditorView instance with the gutter to annotate
  constructor: (editorView) ->
    @editor = editorView.getEditor()
    @gutter = editorView.gutter
    @markers = null

  # Public: Clear previously rendered annotations
  clear: ->
    return unless @markers
    m.destroy() for m in @markers
    @markers = null

  # Public: Render messages in on this gutter view
  #
  # messages - An array of messages to annotate:
  #           :level  - the annotation error level ('error', 'warning')
  #           :range - The buffer range that the annotation should be placed on
  render: (messages) ->
    return unless @gutter.isVisible()
    @clear()

    @markers ?= []
    for message in messages
      klass = if message.level == 'error'
        'linter-error'
      else if message.level == 'warning'
        'linter-warning'
      return unless klass?  # skip other messages

      startRow = message.range.start.row
      marker = @editor.markBufferRange [[startRow, 0], [startRow, Infinity]],
                                       invalidate: 'never'
      @editor.decorateMarker marker, type: 'gutter', class: klass
      @markers.push(marker)


module.exports = GutterView
