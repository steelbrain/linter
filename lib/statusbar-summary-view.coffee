{View} = require 'space-pen'
{moveToNextMessage} = require './utils'

# Status Bar View
class StatusBarSummaryView
  remove: ->
    # TODO: call this when the linter is disabled
    @tile.destroy() if @tile?
    @tile = null

  # Render the view
  render: (messages, editor) ->
    statusBar = document.querySelector("status-bar")
    return unless statusBar?

    # Hide the last version of this view
    @remove()

    info = warning = error = 0
    for item in messages
      info += 1 if item.level == 'info'
      warning += 1 if item.level == 'warning'
      error += 1 if item.level == 'error'

    return if info + warning + error == 0

    el = new StatusBarSummary(messages, editor, info, warning, error)
    @tile = statusBar.addRightTile({item: el, priority: 100})

class StatusBarSummary extends View
  initialize: (messages, editor) ->
    return unless messages.length > 0

    @on 'click', ->
      moveToNextMessage messages, editor

  @content: (messages, editor, info, warning, error) ->
    @div class: 'linter-summary inline-block', =>
      if error > 0
        @div class: 'linter-error inline-block', error, =>
          @span class: 'icon-right'
      if warning > 0
        @div class: 'linter-warning inline-block', warning, =>
          @span class: 'icon-right'
      if info > 0
        @div class: 'linter-info inline-block', info, =>
          @span class: 'icon-right'

  detached: ->
    @off 'click', '.linter-summary-click-container'

module.exports = StatusBarSummaryView
