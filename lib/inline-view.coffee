{View} = require 'space-pen'
_ = require 'lodash'

class InlineView
  remove: ->
    @decoration.destroy() if @decoration?
    @decoration = null

  render: (messages, editor) ->
    cursor = editor.getLastCursor()
    if cursor
      # it's only safe to call getCursorBufferPosition when there are cursors
      marker = cursor.getMarker()
      position = cursor.getBufferPosition()
    else
      return # there's nothing to render
    currentLine = position.row + 1

    # If nothing has changed, return early
    if currentLine == @lastLine and _.isEqual(messages, @lastMessages)
      return
    else
      @lastLine = currentLine
      @lastMessages = messages

    # Hide the last version of this view
    @remove()

    # No more errors on the file, return
    return unless messages.length > 0

    # Config value if you want to limit the status bar report
    # if your cursor is in the range or error, or on the line
    limitOnErrorRange = (atom.config.get('linter.statusBar') ==
                         'Show error if the cursor is in range')

    messages = messages.reduce(
      (memo, item, index) ->
        show = if limitOnErrorRange
          item.range?.containsPoint(position) and index <= 10
        else
          item.range?.start.row + 1 is currentLine
        if show
          memo.push
            src: item.linter
            content: item.message
            level: item.level
        memo
      , []
      )

    return unless messages.length > 0

    @decoration = editor.decorateMarker marker,
      type: 'overlay'
      item: new MessageBubble(messages)


class MessageBubble extends View
  @content: (messages) ->
    @div class: "select-list popover-list linter-list", =>
      @ul class: "list-group", =>
        for msg in messages
          @li =>
            @span class: "linter-name highlight-#{msg.level}", msg.src
            @span class: "linter-content", msg.content

module.exports = InlineView
