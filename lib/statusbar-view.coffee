{View} = require 'atom'

copyPaste = require('copy-paste')
  .noConflict()
  .silent()

# Status Bar View
class StatusBarView extends View

  @content: ->
    @div class: 'tool-panel panel-bottom padded text-smaller', =>
      @dl class: 'linter-statusbar text-smaller', outlet: 'violations',

  show: ->
    super
    # Bind `.error-message` to copy the text on click
    @find('.error-message').on 'click', ->
      copyPaste.copy @innerText

  hide: ->
    # Remove registred events before hidding the status bar
    # Avoid memory leaks after long usage
    @find('.error-message').off()
    super

  computeMessages: (messages, position, currentLine, limitOnErrorRange) ->
    # Clear `violations` div
    @violations.empty()

    # Let's go through all the violations reported
    for item, index in messages
      # Condition for cursor into error range
      showInRange = (item.range?.containsPoint(position)) and index <= 10 and limitOnErrorRange
      # Condition for cursor on error line
      showOnline = (item.range?.start.row + 1) is currentLine and not limitOnErrorRange

      # If one of the conditions is true, let's show the StatusBar
      if showInRange or showOnline
        pos = "line: #{item.line}"
        if item.col? then pos = "#{pos} / col: #{item.col}"
        violation =
          """
            <dt>
              <span class='highlight-#{item.level}'>#{item.linter}</span>
            </dt>
            <dd>
              <span class='error-message'>#{item.message}</span>
              <span class='pos'>#{pos}</span>
            </dd>
          """

        # Add the violation to the StatusBar
        @violations.append violation
        # Show the StatusBar
        @show()

  # Render the view
  render: (messages, paneItem) ->
    # preppend this view the bottom
    atom.workspaceView.prependToBottom this

    # Config value if you want to limit the status bar report
    # if your cursor is in the range or error, or on the line
    limitOnErrorRange = atom.config.get 'linter.showStatusBarWhenCursorIsInErrorRange'

    # Hide the last version of this view
    @hide()

    # No more errors on the file, return
    return unless messages.length > 0

    # Easy fix for https://github.com/AtomLinter/Linter/issues/99
    try
      if not paneItem
        paneItem = atom.workspaceView.getActivePaneItem()
      currentLine = undefined
      if position = paneItem?.getCursorBufferPosition?()
        currentLine = position.row + 1
    catch e
      error = e

    @computeMessages messages, position, currentLine, limitOnErrorRange unless error

module.exports = StatusBarView
