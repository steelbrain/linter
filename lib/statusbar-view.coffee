{View} = require 'atom'

# Status Bar View
class StatusBarView extends View

  @content: ->
    @div class: 'tool-panel panel-bottom padded text-smaller', =>
      @dl class: 'linter-statusbar text-smaller', outlet: 'violations',

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
        @violations.append "<dt><span class=\"highlight-#{item.level}\">#{item.linter}</span></dt><dd>#{item.message}</dd>"
        @show()

module.exports = StatusBarView
