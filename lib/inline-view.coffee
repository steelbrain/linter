{View} = require 'atom'
_ = require 'lodash'

class InlineView
  remove: ->
    # TODO: Avoid this awkwardness by combining InlineView and MessageBubble
    @hide()

  hide: ->
    @messageBubble.remove() if @messageBubble?
    @messageBubble = null

  render: (messages, editorView) ->
    if editorView.editor.getLastCursor()
      # it's only safe to call getCursorBufferPosition when there are cursors
      position = editorView.editor.getCursorBufferPosition()
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
    @hide()

    # No more errors on the file, return
    return unless messages.length > 0

    # Config value if you want to limit the status bar report
    # if your cursor is in the range or error, or on the line
    limitOnErrorRange = atom.config.get 'linter.showStatusBarWhenCursorIsInErrorRange'

    for item, index in messages
      show = if limitOnErrorRange
        item.range?.containsPoint(position) and index <= 10
      else
        item.range?.start.row + 1 is currentLine
      if show
        if @messageBubble
          @messageBubble.add(item.linter, item.message)
        else
          @messageBubble = new MessageBubble(
            editorView: editorView
            title: item.linter
            line: item.line
            start: item.range.start.column
            end: item.range.end.column
            content: item.message
            klass: "comment-#{item.level}"
          )


class MessageBubble extends View
  @content: (params) ->
    @div class: "inline-message #{params.klass}", style: params.style, =>
      for msg in params.messages
        @div class: "message-content", =>
          @div class: "message-source", =>
            @text msg.src
          @text msg.content

  constructor: ({editorView, title, line, start, end, content, klass, min}) ->
    @title = title
    @line = line - 1
    @start = start
    @end = end
    @content = content
    @klass = klass
    @editor = editorView.editor
    @editorView = editorView
    @messages = [{content: @content, src: @title}]
    style = @calculateStyle(@line, @start)
    super({messages: @messages, klass: @klass, style: style})

    if @min
      @minimize()
    pageData = editorView.find(".overlayer")
    if pageData
      pageData.first().prepend(this)

  calculateStyle: (line, start) ->
    if @editorView and @editor
      last = @editor.getBuffer().lineLengthForRow(line)
      fstPos = @editorView.pixelPositionForBufferPosition({row: line, column: 0})
      lastPos = @editorView.pixelPositionForBufferPosition({row: line, column: start})
      top = fstPos.top + @editorView.lineHeight
      left = lastPos.left
      return "position:absolute;left:#{left}px;top:#{top}px;"

  renderMsg: (msg) ->
    View.render ->
      @div class: "message-content", =>
        @div class: "message-source", =>
          @raw msg.src
        @raw msg.content

  update: ->
    this.find(".message-content").remove()
    this.append (@renderMsg(msg) for msg in @messages)

  add: (title, content) ->
    @messages.push({content: content, src: title})
    @update()


module.exports = InlineView
