{View} = require 'atom'
MessageBubble = require 'atom-inline-messages'

copyPaste = require('copy-paste')
  .noConflict()
  .silent()

class InlineView

  hide: ->
    if @message
      @message.remove()

  render: (messages, editor, editorView) ->
    # Config value if you want to limit the status bar report
    # if your cursor is in the range or error, or on the line
    limitOnErrorRange = atom.config.get 'linter.showStatusBarWhenCursorIsInErrorRange'

    # Hide the last version of this view
    @hide()

    # No more errors on the file, return
    return unless messages.length > 0

    try
      if not editor
        editor = atom.workspaceView.getActivePaneItem()
      currentLine = undefined
      if position = editor?.getCursorBufferPosition?()
        currentLine = position.row + 1
    catch e
      error = e

    if @message
      @message.remove()
      @message = null

    for item, index in messages
      # Condition for cursor into error range
      showInRange = (item.range?.containsPoint(position)) and index <= 10 and limitOnErrorRange
      # Condition for cursor on error line
      showOnline = (item.range?.start.row + 1) is currentLine and not limitOnErrorRange

      if showInRange or showOnline
        if @message
          @message.add(item.linter, "<pre>" + item.message + "</pre>")
        else
          @message = new MessageBubble(
            editor: editor
            editorView: editorView
            title: item.linter
            line: item.line
            start: item.range.start.col
            end: item.range.end.col
            content: "<pre>" + item.message + "</pre>"
            klass: "comment-#{item.level}"
          )

module.exports = InlineView
