{Range} = require('atom')
helpers = require('./helpers')

module.exports = Validate =

  linter: (linter) ->
    # set undefined to false for backward compatibility
    linter.modifiesBuffer = Boolean(linter.modifiesBuffer)
    unless linter.grammarScopes instanceof Array
      throw new Error("grammarScopes is not an Array. Got: #{linter.grammarScopes}")
    unless linter.lint?
      throw new Error("Missing linter.lint")
    if typeof linter.lint isnt 'function'
      throw new Error("linter.lint isn't a function")
    return true

  messages: (messages) ->
    unless messages instanceof Array
      throw new Error("Expected messages to be array, provided: #{typeof messages}")
    messages.forEach (result) ->
      unless result.type
        throw new Error "Missing type field on Linter Response"
      unless result.html or result.text
        throw new Error "Missing html/text field on Linter Response"
      result.range = Range.fromObject result.range if result.range?
      result.key = JSON.stringify(result)
      result.class = result.type.toLowerCase().replace(' ', '-')
      Validate.messages(result.trace) if result.trace
    return undefined
