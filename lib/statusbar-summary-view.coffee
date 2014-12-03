{View, Point} = require 'atom'

# Status Bar View
class StatusBarSummaryView extends View

  @content: ->
    @div class: 'linter-summary inline-block'

  showError: (messages) ->
    console.log errorsNb
    html = if errorsNb > 0 then errorsNb else ''
    @find('.linter-summary').html(html)

  # Render the view
  render: (messages) ->
    statusBar = atom.workspaceView.statusBar
    return unless statusBar

    statusBar.prependRight this

    warning = error = 0

    for item in messages
      warning += 1 if item.level == 'warning'
      error += 1 if item.level == 'error'

    html = ''
    if warning > 0
      html = """
        <div class='linter-warning inline-block'>
          #{warning}
          <span class='icon-right'></span>
        </div>
      """

    if error > 0
      html += """
        <div class='linter-error inline-block'>
          #{error}
          <span class='icon-right'></span>
        </div>
      """

    this.html(html)

module.exports = StatusBarSummaryView
