{View} = require 'space-pen'

module.exports = class LeftTile extends View
  @content: (numErrors) ->
    if numErrors
      @div class: 'linter-error inline-block', =>
        @span class: 'icon icon-x', =>
          @text if numErrors is 1 then " #{numErrors} error" else " #{numErrors} errors"
    else
      @div class: 'linter-success inline-block', =>
        @span class: 'icon icon-check', =>
          @text ' No errors'
