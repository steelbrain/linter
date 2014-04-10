{View} = require 'atom'

# Status Bar View
class StatusBarView extends View

  @content: ->
    @div class: 'tool-panel panel-bottom padded text-smaller', =>
      @ul 'linter-statusbar text-smaller text-error', outlet: 'violations',

  # Render the view
  render: (messages) ->
    atom.workspaceView.prependToBottom(@)

    return unless messages.length > 0

    paneItem = atom.workspaceView.getActivePaneItem()
    currentLine = undefined
    if position = paneItem?.getCursorBufferPosition?()
      currentLine = position.row + 1
    @hide()
    @violations.empty()
    for item in messages
      if parseInt(item.line) is currentLine
        console.log @violations
        @violations.append "<li>#{item.message}</li>"
        @show()

module.exports = StatusBarView
