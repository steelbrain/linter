{View} = require 'atom'

# Status Bar View
class StatusBarView extends View

  @content: ->
    @div class: 'tool-panel panel-bottom padded text-smaller', =>
      @dl class: 'linter-statusbar text-smaller', outlet: 'violations',

  # Render the view
  render: (messages, paneItem) ->
    atom.workspaceView.prependToBottom this

    # Config value if you want to limit the status bar report
    # if your cursor is in the range or error, or on the line
    limitOnErrorRange = atom.config.get 'linter.Show Status Bar when cursor on error line'

    # Hide the last version of this view
    @hide()

    # No more errors on the file, return
    return unless messages.length > 0

    if not paneItem
      paneItem = atom.workspaceView.getActivePaneItem()
    currentLine = undefined
    if position = paneItem?.getCursorBufferPosition?()
      currentLine = position.row + 1

    # Remove all old violations
    @violations.empty()

    # Let's go through all the violations reported
    for item, index in messages
      # Condition for cursor into error range
      showInRange = (item.range?.containsPoint(position)) and index <= 10 and limitOnErrorRange
      # Condition for cursor on error line
      showOnline = parseInt(item.line) is currentLine and not limitOnErrorRange

      # If one of the conditions is true, let's show the StatusBar
      if showInRange or showOnline
        pos = "line: #{item.line}"
        if item.col? then pos = "#{pos} / col: #{item.col}"
        violation =
          """
            <dt>
              <span class='highlight-#{item.level}'>
                #{item.linter}
              </span>
            </dt>
            <dd>
              #{item.message}
              <span class='pos'>
                #{pos}
              </span>
            </dd>
          """

        # Add the violation to the StatusBar
        @violations.append violation
        # Show the StatusBar
        @show()

module.exports = StatusBarView
