{exec, child} = require 'child_process'
{XRegExp} = require 'xregexp'
path = require 'path'

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

  regexFlags: ''

  # current working directory, overridden in linters that need it
  cwd: null

  defaultLevel: 'error'

  linterName: null

  executablePath: null

  isNodeExecutable: no

  constructor: (editor) ->
    @cwd = path.dirname(editor.getUri())

  getCmd: (filePath) ->
    if /@filename/i.test(@cmd)
      cmd = @cmd.replace('@filename', filePath)
    else
      cmd = "#{@cmd} #{filePath}"

    if @executablePath
      cmd = "#{@executablePath}/#{cmd}"

    if @isNodeExecutable
      cmd = "#{@getNodeExecutablePath()} #{cmd}"

    cmd

  getNodeExecutablePath: ->
    path.join require.resolve('package'), '..', 'apm/node_modules/atom-package-manager/bin/node'

  lintFile: (filePath, callback) ->
    console.log 'linter: run linter command'
    console.log @getCmd(filePath)
    console.log @cwd
    exec @getCmd(filePath), {cwd: @cwd}, (error, stdout, stderr) =>
      if stderr
        console.log stderr
      console.log stdout
      @processMessage(stdout, callback)

  processMessage: (message, callback) ->
    messages = []
    regex = XRegExp @regex, @regexFlags
    XRegExp.forEach message, regex, (match, i) =>
      console.log match
      messages.push(@createMessage(match))
    , @
    callback messages

  createMessage: (match) ->
    if match.error
      level = 'error'
    else if match.warning
      level = 'warning'
    else
      level = @defaultLevel

    return {
      line: match.line,
      col: match.col,
      level: level,
      message: match.message,
      linter: @linterName
    }

module.exports = Linter
