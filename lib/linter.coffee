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

  # current working directory, overridden in linters that need it
  cwd: null

  defaultLevel: 'error'

  linterName: null

  executablePath: null

  getCmd: (filePath)->
    if /@filename/i.test(@cmd)
      cmd = @cmd.replace('@filename', filePath)
    else
      cmd = "#{@cmd} #{filePath}"
    if @executablePath
      cmd = "#{@executablePath}/#{cmd}"
    cmd

  lintFile: (filePath, callback) ->
    console.log 'linter: run linter command'
    console.log @getCmd(filePath)
    exec @getCmd(filePath), {cwd: @cwd}, (error, stdout, stderr) =>
      if stderr
        console.log stderr
      @processMessage(stdout, callback)

  processMessage: (message, callback) ->
    messages = []
    regex = XRegExp @regex
    XRegExp.forEach message, regex, (match, i) =>
        if match.error
          level = 'error'
        else if match.warning
          level = 'warning'
        else
          level = @defaultLevel
        messages.push({line: match.line, col: match.col, level: level, message: match.message, linter: @linterName})
    , @
    callback messages

module.exports = Linter
