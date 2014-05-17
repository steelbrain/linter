# Gutter view for the plugin
class GutterView

  # Instantiation
  constructor: (editorView) ->
    @editorView = editorView
    @gutter = @editorView.gutter

  clear: ->
    @gutter.removeClassFromAllLines('linter-error')
    @gutter.removeClassFromAllLines('linter-warning')

  render: (messages) ->
    return unless @gutter.isVisible()

    for message in messages
      if message.range
        line = message.range.start.row
      else
        line = message.line - 1
      if message.level == 'error'
        @gutter.addClassToLine(line, 'linter-error')

      if message.level == 'warning'
        @gutter.addClassToLine(line, 'linter-warning')

module.exports = GutterView
