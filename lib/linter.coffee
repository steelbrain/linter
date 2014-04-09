{exec, child} = require 'child_process'
{XRegExp} = require 'xregexp'

# The base class for linters.
# Subclasses must at a minimum define the attributes syntax, cmd, and regex.
class Linter

  # The syntax that the linter handles. May be a string or
  # list/tuple of strings. Names should be all lowercase.
  @syntax: ''

  # A string, list, tuple or callable that returns a string, list or tuple,
  # containing the command line (with arguments) used to lint.
  cmd: ''

  # A regex pattern used to extract information from the executable's output.
  regex: ''

  lintFile: (filePath, callback) ->
    console.log 'linter: run linter command'
    console.log @
    exec "#{@cmd} #{filePath}", (error, stdout, stderr) =>
      @processMessage(stdout, callback)

  processMessage: (message, callback) ->
    regex = XRegExp @regex
    callback XRegExp.forEach message, regex, (match, i) ->
        if match.error
          level = 'error'
        else
          level = 'warning'
        @.push({line: match.line, col: match.col, level: level, message: match.message})
    , []

module.exports = Linter