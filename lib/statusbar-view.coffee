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
    @find('.copy').on 'click', ->
      copyPaste.copy @parentElement.getElementsByClassName('error-message')[0].innerText
    # Bind `.goToError` to go to the lint error
    @find('.goToError').on 'click', ->
      editorView = atom.workspaceView.getActiveView()
      editor = editorView.getEditor()
      editor.setCursorBufferPosition(new Point(@.dataset.line-1, @.dataset.col))

  hide: ->
    # Remove registred events before hidding the status bar
    # Avoid memory leaks after long usage
    @find('.copy').off()
    @find('.goToError').off()
    super

  computeMessages: (messages, position, currentLine, showAllErrors, limitOnErrorRange) ->
    # Clear `violations` div
    @violations.empty()

    # Let's go through all the violations reported
    for item, index in messages
      # Condition for cursor into error range
      showInRange = (item.range?.containsPoint(position)) and index <= 10 and limitOnErrorRange
      # Condition for cursor on error line
      showOnline = (item.range?.start.row + 1) is currentLine and not limitOnErrorRange

      # If one of the conditions is true, let's show the StatusBar
      if showInRange or showOnline or showAllErrors
        pos = "line: #{item.line}"
        if item.col? then pos = "#{pos} / col: #{item.col}"
        violation =
          """
            <dt>
              <span class='highlight-#{item.level}'>#{item.linter}</span>
            </dt>
            <dd>
              <span class='goToError' data-line='#{item.line}' data-col='#{item.col or 0}'>
                <span class='error-message'>#{item.message}</span>
                <span class='pos'>#{pos}</span>
              </span>
              <span class='copy'>Copy</span>
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
    # Display all errors in the file if it set to true
    showAllErrors = atom.config.get 'linter.showAllErrorsInStatusBar'

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

    @computeMessages messages, position, currentLine, showAllErrors, limitOnErrorRange unless error

module.exports = StatusBarView
