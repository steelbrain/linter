{Range} = require('atom')

Helpers = module.exports =
  validateResults: (results) ->
    if (not results) or results.constructor.name isnt 'Array'
      throw new Error "Got invalid response from Linter, Type: #{typeof results}"
    for result in results
      unless result.type
        throw new Error "Missing type field on Linter Response, Got: #{Object.keys(result)}"
      result.range = Range.fromObject result.range if result.range?
      result.class = result.type.toLowerCase().replace(' ', '-')
      Helpers.validateResults(result.trace) if result.trace
    results
  validateLinter: (linter) ->
    unless linter.grammarScopes instanceof Array
      message = "grammarScopes is not an Array. (see console for more info)"
      console.warn(message)
      console.warn('grammarScopes', linter.grammarScopes)
      throw new Error(message)

    unless linter.lint?
      throw new Error("Missing linter.lint")

    if typeof linter.lint isnt 'function'
      throw new Error("linter.lint isn't a function")

    return true
