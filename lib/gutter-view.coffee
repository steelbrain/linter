# Gutter view for the plugin

# Public: Represents a linter gutter annotation view
class GutterView

  # Public: Create a linter gutter view for annotating with an Atom.Editor
  # instance
  #
  # editorView  - Atom.EditorView instance with the gutter to annotate
  constructor: (editorView) ->
    @editorView = editorView
    @gutter = @editorView.gutter

  # Public: Clear previously rendered annotations
  clear: ->
    @gutter.removeClassFromAllLines('linter-error')
    @gutter.removeClassFromAllLines('linter-warning')

  # Public: Render messages in on this gutter view
  #
  # messages - An array of messages to annotate:
  #           :level  - the annotation error level ('error', 'warning')
  #           :range - The buffer range that the annotation should be placed on
  render: (messages) ->
    return unless @gutter.isVisible()
    @clear()

    for message in messages
      line = message.range.start.row
      if message.level == 'error'
        @gutter.addClassToLine(line, 'linter-error')

      if message.level == 'warning'
        @gutter.addClassToLine(line, 'linter-warning')

module.exports = GutterView
