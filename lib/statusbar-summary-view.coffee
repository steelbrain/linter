{View} = require 'atom'

# Status Bar View
class StatusBarSummaryView
  remove: ->
    @decoration.remove() if @decoration?
    @decoration = null

  # Render the view
  render: (messages) ->
    statusBar = atom.workspaceView.statusBar
    return unless statusBar

    warning = error = 0

    for item in messages
      warning += 1 if item.level == 'warning'
      error += 1 if item.level == 'error'

    # Hide the last version of this view
    @remove()

    @decoration = new StatusBarSummary(warning or 0, error or 0)

    statusBar.prependRight @decoration

class StatusBarSummary extends View
  @content: (warning, error) ->
    @div class: 'linter-summary inline-block', =>
      @div class: 'linter-warning inline-block', warning, =>
        @span class: 'icon-right'
      @div class: 'linter-error inline-block', error, =>
        @span class: 'icon-right'

module.exports = StatusBarSummaryView
