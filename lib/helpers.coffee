module.exports = Helpers =
  # Validates that the results passed to Linter Base by a Provider contain the
  #   information needed to display an issue.
  validateResults: (results) ->
    if (not results) or results.constructor.name isnt 'Array'
      throw new Error "Got invalid response from Linter, Type: #{typeof results}"
    for result in results
      unless result.type
        throw new Error "Missing type field on Linter Response, Got: #{Object.keys(result)}"
      {Range} = require('atom')
      result.range = Range.fromObject result.range if result.range?
      result.class = result.type.toLowerCase().replace(' ', '-')
      Helpers.validateResults(result.trace) if result.trace
    results

  # Validates that a provider is capable of providing the Base Linter info
  #   needed to be used at lint time.
  validateLinter: (linter) ->
    unless linter.grammarScopes instanceof Array
      throw new Error("grammarScopes is not an Array. Got: #{linter.grammarScopes})")
    unless linter.lint?
      throw new Error("Missing linter.lint")
    if typeof linter.lint isnt 'function'
      throw new Error("linter.lint isn't a function")
    return true

  # Everything past this point relates to CLI helpers as loosly demoed out in:
  #   https://gist.github.com/steelbrain/43d9c38208bf9f2964ab

  exec: (command, options = {}) ->
    throw new Error "Nothing to execute." if not arguments.length
    child_process = require 'child_process'
    return new Promise (resolve, reject) ->
      resolve(child_process.exec(command, options))

  # This should only be used if the linter is only working with files in their
  #   base directory. Else wise they should use `Helpers#exec`.
  execFilePath: (command, filePath, options = {}) ->
    throw new Error "Nothing to execute." if not arguments.length
    throw new Error "No File Path to work with." if not filePath
    path = require 'path'
    return new Promise (resolve, reject) ->
      file = path.basename(filePath)
      options.cwd = path.dirname(filePath) if not options.cwd
      resolve(Helpers.exec("#{command} #{file}"), options)
