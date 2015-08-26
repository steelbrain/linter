{Range} = require('atom')
helpers = require('./helpers')

module.exports = Validate =

  linter: (linter) ->
    # set undefined to false for backward compatibility
    linter.modifiesBuffer = Boolean(linter.modifiesBuffer)
    unless linter.grammarScopes instanceof Array
      throw new Error("grammarScopes is not an Array. Got: #{linter.grammarScopes}")
    if linter.lint
      throw new Error("linter.lint isn't a function on provider") if typeof linter.lint isnt 'function'
    else
      throw new Error('Missing linter.lint on provider')
    return true

  messages: (messages) ->
    unless messages instanceof Array
      throw new Error("Expected messages to be array, provided: #{typeof messages}")
    messages.forEach (result) ->
      if result.type
        throw new Error 'Invalid type field on Linter Response' if typeof result.type isnt 'string'
      else
        throw new Error 'Missing type field on Linter Response'
      if result.html
        throw new Error 'Invalid html field on Linter Response' if typeof result.html isnt 'string'
      else if result.text
        throw new Error 'Invalid text field on Linter Response' if typeof result.text isnt 'string'
      else
        throw new Error 'Missing html/text field on Linter Response'
      result.range = Range.fromObject result.range if result.range?
      result.key = JSON.stringify(result)
      result.class = result.type.toLowerCase().replace(' ', '-')
      Validate.messages(result.trace) if result.trace
    return undefined
