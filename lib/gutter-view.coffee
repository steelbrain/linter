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
      if message.level == 'error'
        @gutter.addClassToLine(message.line - 1, 'linter-error')

      if message.level == 'warning'
        @gutter.addClassToLine(message.line - 1, 'linter-warning')

module.exports = GutterView
