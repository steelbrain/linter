{View} = require 'space-pen'

# Status Bar View
class StatusBarSummaryView
  remove: ->
    @decoration.remove() if @decoration?
    @decoration = null

  # Render the view
  render: (messages) ->
    statusBar = atom.workspaceView.statusBar
    return unless statusBar

    info = warning = error = 0

    for item in messages
      warning += 1 if item.level == 'warning'
      error += 1 if item.level == 'error'
      info += 1 if item.level == 'info'

    # Hide the last version of this view
    @remove()

    @decoration = new StatusBarSummary(info or 0, warning or 0, error or 0)

    statusBar.prependRight @decoration

class StatusBarSummary extends View
  @content: (info, warning, error) ->
    @div class: 'linter-summary inline-block', =>
      @div class: 'linter-error inline-block', error, =>
        @span class: 'icon-right'
      @div class: 'linter-warning inline-block', warning, =>
        @span class: 'icon-right'
      @div class: 'linter-info inline-block', info, =>
        @span class: 'icon-right'

module.exports = StatusBarSummaryView
