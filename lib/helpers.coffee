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

  exec: (command, options = {stream: 'stdout'}) ->
    throw new Error "Nothing to execute." if not arguments.length
    child_process = require 'child_process'
    return new Promise (resolve, reject) ->
      process = child_process.exec(command, options)
      data = []
      if options.stream == 'stderr'
        process.stderr.on 'data', (d) -> data.push(d.toString())
      else
        process.stdout.on 'data', (d) -> data.push(d.toString())
      process.on 'close', ->
        console.log data
        resolve(data)

  # This should only be used if the linter is only working with files in their
  #   base directory. Else wise they should use `Helpers#exec`.
  execFilePath: (command, filePath, options = {}) ->
    throw new Error "Nothing to execute." if not arguments.length
    throw new Error "No File Path to work with." if not filePath
    path = require 'path'
    child_process = require 'child_process'
    return new Promise (resolve, reject) ->
      file = path.basename(filePath)
      options.cwd = path.dirname(filePath) if not options.cwd
      command = "#{command} #{filePath}"
      process = child_process.exec(command, options)
      data = []
      if options.stream == 'stderr'
        process.stderr.on 'data', (d) -> data.push(d.toString())
      else
        process.stdout.on 'data', (d) -> data.push(d.toString())
      process.on 'close', ->
        resolve(data)

  # Due to what we are attempting to do, the only viable solution right now is
  #   XRegExp.
  #
  # Follows the following format taken from 0.x.y API.
  #
  # file: the file where the issue Exists
  # type: the type of issue occuring here
  # message: the message to show in the linter views (required)
  # line: the line number on which to mark error (required if not lineStart)
  # lineStart: the line number to start the error mark (optional)
  # lineEnd: the line number on end the error mark (optional)
  # col: the column on which to mark, will utilize syntax scope to higlight the
  #      closest matching syntax element based on your code syntax (optional)
  # colStart: column to on which to start a higlight (optional)
  # colEnd: column to end highlight (optional)
  # We place priority on `lineStart` and `lineEnd` over `line.`
  # We place priority on `colStart` and `colEnd` over `col.`
  parse: (data, regex, options = {baseReduction: 1}) ->
    XRegExp = require('xregexp').XRegExp
    new Promise (resolve, reject) ->
      toReturn = []
      regex = XRegExp(regex)
      for line in data
        match = XRegExp.exec(line, regex)
        if match
          if match.lineStart
            lineStart = match.lineStart - options.baseReduction
          else if match.line
            lineStart = match.line - options.baseReduction
          else
            lineStart = 0
          if match.colStart
            colStart = match.colStart - options.baseReduction
          else if match.col
            colStart = match.col - options.baseReduction
          else
            colStart = 0
          if match.lineEnd
            lineEnd = match.lineEnd - options.baseReduction
          else if match.line
            lineEnd = match.line - options.baseReduction
          else
            lineEnd = 0
          if match.colEnd
            colEnd = match.colEnd - options.baseReduction
          else if match.col
            colEnd = match.col - options.baseReduction
          else
            colEnd = 0
          toReturn.push(
            type: match.type,
            text: match.message,
            filePath: match.file
            range: [[lineStart, colStart], [lineEnd, colEnd]]
          )
      resolve(toReturn)
