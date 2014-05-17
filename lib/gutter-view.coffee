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
      line = if message.range then message.range.start.row else (message.line - 1)
      if message.level == 'error'
        @gutter.addClassToLine(line, 'linter-error')

      if message.level == 'warning'
        @gutter.addClassToLine(line, 'linter-warning')

module.exports = GutterView
