{Point} = require 'atom'
{View} = require 'space-pen'

_ = require 'lodash'

# Status Bar View
class StatusBarView extends View

  @content: ->
    @div class: 'padded text-smaller', =>
      @dl class: 'linter-statusbar', outlet: 'violations',

  initialize: ->
    # Bind `.copy` to copy the text on click
    @on 'click', '.copy', ->
      el = @parentElement.getElementsByClassName('error-message')[0]
      atom.clipboard.write el.innerText
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

  detached: ->
    @off 'click', '.copy'
    @off 'click', '.goToError'

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
        message = _.escape(item.message)
        violation =
          """
            <dt>
              <span class='highlight-#{item.level}'>#{item.linter}</span>
            </dt>
            <dd>
              <span class='copy icon-clippy'></span>
              <span class='goToError' data-line='#{item.line - 1}' data-col='#{item.col - 1 or 0}'>
                <span class='error-message linter-line-#{item.line - 1}'>#{message}</span>
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

  # Render the view
  render: (messages, editor) ->
    statusBarConfig = atom.config.get 'linter.statusBar'
    # Config value if you want to limit the status bar report
    # if your cursor is in the range or error, or on the line
    limitOnErrorRange = statusBarConfig == 'Show error if the cursor is in range'
    # Display all errors in the file if it set to true
    @showAllErrors = statusBarConfig == 'Show all errors'

    # Hide the last version of this view
    @hide()

    # No more errors on the file, return
    return unless messages.length > 0

    if editor.getLastCursor()?
      # it's only safe to call getCursorBufferPosition when there are cursors
      position = editor.getCursorBufferPosition()
    else
      return # there's nothing to render

    # TODO: why not have computeMessages get currentLine from position?
    currentLine = position.row
    @computeMessages messages, position, currentLine, limitOnErrorRange

    unless @added
      atom.workspace.addBottomPanel item: this
      @added = true

module.exports = StatusBarView
