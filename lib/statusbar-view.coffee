{View} = require 'atom'

# Status Bar View
class StatusBarView extends View

  @content: ->
    @div class: 'tool-panel panel-bottom padded text-smaller', =>
      @dl class: 'linter-statusbar text-smaller', outlet: 'violations',

  # Render the view
  render: (messages, paneItem) ->
    atom.workspaceView.prependToBottom(@)
    @hide()
    return unless messages.length > 0
    if not paneItem
      paneItem = atom.workspaceView.getActivePaneItem()
    currentLine = undefined
    if position = paneItem?.getCursorBufferPosition?()
      currentLine = position.row + 1
    @violations.empty()
    i = 0
    for item in messages
      if parseInt(item.line) is currentLine and i <= 10
        @violations.append "<dt><span class=\"highlight-#{item.level}\">#{item.linter}</span></dt><dd>#{item.message}</dd>"
        @show()
        i++

module.exports = StatusBarView
