{View, Point} = require 'atom'

copyPaste = require('copy-paste')
  .noConflict()
  .silent()

# Status Bar View
class StatusBarView extends View

  @content: ->
    @div class: 'tool-panel panel-bottom padded text-smaller', =>
      @dl class: 'linter-statusbar', outlet: 'violations',

  show: ->
    super
    # Bind `.copy` to copy the text on click
    @on 'click', '.copy', ->
      copyPaste.copy @parentElement.getElementsByClassName('error-message')[0].innerText
    # Bind `.goToError` to go to the lint error
    @on 'click', '.goToError', ->
      line = parseInt(@dataset.line, 10)
      col = parseInt(@dataset.col, 10)
      atom.workspace.getActiveEditor()?.setCursorBufferPosition(new Point(line, col))

  highlightLines: (currentLine) ->
    return unless @showAllErrors
    # Remove previous selection
    @find('.error-message').removeClass('message-highlighted')

    $line = @find('.linter-line-' + currentLine)
    # If the selected line contains an error message, highlight the error
    $line?.addClass('message-highlighted')

  hide: ->
    # Remove registred events before hidding the status bar
    # Avoid memory leaks after long usage
    @off 'click', '.copy'
    @off 'click', '.goToError'
    super

  computeMessages: (messages, position, currentLine, limitOnErrorRange) ->
    # Clear `violations` div
    @violations.empty()

    # messages are sorted when all errors are to be displayed
    messages.sort((a, b) -> a.line - b.line) if @showAllErrors

    # Let's go through all the violations reported
    for item, index in messages
      # Condition for cursor into error range
      showInRange = item.range?.containsPoint(position) and index <= 10 and limitOnErrorRange
      # Condition for cursor on error line
      showOnLine = item.range?.start.row is currentLine and not limitOnErrorRange

      # If one of the conditions is true, let's show the StatusBar
      if showInRange or showOnLine or @showAllErrors
        pos = "line: #{item.line}"
        if item.col? then pos = "#{pos} / col: #{item.col}"
        violation =
          """
            <dt>
              <span class='highlight-#{item.level}'>#{item.linter}</span>
            </dt>
            <dd>
              <span class='copy icon-clippy'></span>
              <span class='goToError' data-line='#{item.line - 1}' data-col='#{item.col - 1 or 0}'>
                <span class='error-message linter-line-#{item.line - 1}'>#{item.message}</span>
                <span class='pos'>#{pos}</span>
              </span>
            </dd>
          """

        # Add the violation to the StatusBar
        @violations.append violation

    # Show the StatusBar only if there are error(s)
    if violation?
      @show()
      @highlightLines(currentLine)

  getCursorPosition: ->
    # Easy fix for https://github.com/AtomLinter/Linter/issues/99
    try
      if not paneItem
        paneItem = atom.workspaceView.getActivePaneItem()
        position = paneItem?.getCursorBufferPosition?()
    catch e
      error = e

    return position or undefined

  # Render the view
  render: (messages, paneItem) ->
    # preppend this view the bottom
    atom.workspaceView.prependToBottom this

    # Config value if you want to limit the status bar report
    # if your cursor is in the range or error, or on the line
    limitOnErrorRange = atom.config.get 'linter.showStatusBarWhenCursorIsInErrorRange'
    # Display all errors in the file if it set to true
    @showAllErrors = atom.config.get 'linter.showAllErrorsInStatusBar'

    # Hide the last version of this view
    @hide()

    # No more errors on the file, return
    return unless messages.length > 0

    position = @getCursorPosition()
    return unless position

    currentLine = position.row

    @computeMessages messages, position, currentLine, limitOnErrorRange

module.exports = StatusBarView
