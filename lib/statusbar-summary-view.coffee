{View} = require 'space-pen'

# Status Bar View
class StatusBarSummaryView
  remove: ->
    # TODO: call this when the linter is disabled
    @tile.destroy() if @tile?
    @tile = null

  # Render the view
  render: (messages) ->
    statusBar = document.querySelector("status-bar")
    return unless statusBar?

    warning = error = 0

    for item in messages
      warning += 1 if item.level == 'warning'
      error += 1 if item.level == 'error'

    # Hide the last version of this view
    @remove()

    el = new StatusBarSummary(warning, error)
    @tile = statusBar.addRightTile({item: el, priority: 100})

class StatusBarSummary extends View
  @content: (warning, error) ->
    @div class: 'linter-summary inline-block', =>
      @div class: 'linter-warning inline-block', warning, =>
        @span class: 'icon-right'
      @div class: 'linter-error inline-block', error, =>
        @span class: 'icon-right'

module.exports = StatusBarSummaryView
