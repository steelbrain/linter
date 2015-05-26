{View} = require 'space-pen'

module.exports = class LeftTile extends View
  @content: (nbErrors) ->
    if nbErrors
      return @div class: 'linter-error inline-block', =>
        @span class: 'badge badge-flexible badge-error', =>
          @text '✘'
        @text if nbErrors > 1 then " #{nbErrors} errors" else " #{nbErrors} error"
    else
      return @div class: 'linter-success inline-block', =>
        @span class: 'badge badge-flexible badge-success', =>
          @text '✔'
        @text ' No errors'
