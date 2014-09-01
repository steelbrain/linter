fs = require 'fs'
path = require 'path'
{Range, Point, BufferedProcess} = require 'atom'
_ = require 'lodash'
{XRegExp} = require 'xregexp'
{log, warn} = require './utils'

# Public: The base class for linters.
# Subclasses must at a minimum define the attributes syntax, cmd, and regex.
class Linter

  # The syntax that the linter handles. May be a string or
  # list/tuple of strings. Names should be all lowercase.
  @syntax: ''

  # A string or array containing the command line (with arguments) used to
  # lint.
  cmd: ''

  # A regex pattern used to extract information from the executable's output.
  # regex should construct match results for the following keys
  #
  # message: the message to show in the linter views (required)
  # line: the line number on which to mark error (required if not lineStart)
  # lineStart: the line number to start the error mark (optional)
  # lineEnd: the line number on end the error mark (optional)
  # col: the column on which to mark, will utilize syntax scope to higlight the
  #      closest matching syntax element based on your code syntax (optional)
  # colStart: column to on which to start a higlight (optional)
  # colEnd: column to end highlight (optional)
  regex: ''

  regexFlags: ''

  # current working directory, overridden in linters that need it
  cwd: null

  defaultLevel: 'error'

  linterName: null

  executablePath: null

  isNodeExecutable: no

  # TODO: what does this mean?
  errorStream: 'stdout'

  # Public: Construct a linter passing it's base editor
  constructor: (@editor) ->
    @cwd = path.dirname(editor.getUri())

  # Private: Exists mostly so we can use statSync without slowing down linting.
  # TODO: Do this at constructor time?
  _cachedStatSync: _.memoize (path) ->
    fs.statSync path

  # Private: get command and args for atom.BufferedProcess for execution
  getCmdAndArgs: (filePath) ->
    cmd = @cmd

    # ensure we have an array
    cmd_list = if Array.isArray cmd
      cmd.slice()  # copy since we're going to modify it
    else
      cmd.split ' '

    cmd_list.push filePath

    if @executablePath
      stats = @_cachedStatSync @executablePath
      if stats.isDirectory()
        cmd_list[0] = path.join @executablePath, cmd_list[0]
      else
        # because of the name exectablePath, people sometimes set it to the
        # full path of the linter executable
        cmd_list[0] = @executablePath

    if @isNodeExecutable
      cmd_list.unshift(@getNodeExecutablePath())

    # if there are "@filename" placeholders, replace them with real file path
    cmd_list = cmd_list.map (cmd_item) ->
      if /@filename/i.test(cmd_item)
        return cmd_item.replace(/@filename/gi, filePath)
      else
        return cmd_item

    log 'command and arguments', cmd_list

    {
      command: cmd_list[0],
      args: cmd_list.slice(1)
    }

  # Private: Provide the node executable path for use when executing a node
  #          linter
  getNodeExecutablePath: ->
    path.join atom.packages.apmPath, '..', 'node'

  # Public: Primary entry point for a linter, executes the linter then calls
  #         processMessage in order to handle standard output
  #
  # Override this if you don't intend to use base command execution logic
  lintFile: (filePath, callback) ->
    # build the command with arguments to lint the file
    {command, args} = @getCmdAndArgs(filePath)

    log 'is node executable: ' + @isNodeExecutable

    # options for BufferedProcess, same syntax with child_process.spawn
    options = {cwd: @cwd}

    dataStdout = []
    dataStderr = []

    stdout = (output) ->
      log 'stdout', output
      dataStdout += output

    stderr = (output) ->
      warn 'stderr', output
      dataStderr += output

    exit = =>
      data = if @errorStream is 'stdout' then dataStdout else dataStderr
      @processMessage data, callback

    process = new BufferedProcess({command, args, options,
                                   stdout, stderr, exit})

    # Don't block UI more than 5seconds, it's really annoying on big files
    setTimeout ->
      process.kill()
    , 5000

  # Private: process the string result of a linter execution using the regex
  #          as the message builder
  #
  # Override this in order to handle message processing in a differen manner
  # for instance if the linter returns json or xml data
  processMessage: (message, callback) ->
    messages = []
    regex = XRegExp @regex, @regexFlags
    XRegExp.forEach message, regex, (match, i) =>
      messages.push(@createMessage(match))
    , this
    callback messages

  # Private: create a message from the regex match return
  #
  # match - Options used to configure linting messages
  #   message: the message to show in the linter views (required)
  #   line: the line number on which to mark error (required if not lineStart)
  #   lineStart: the line number to start the error mark (optional)
  #   lineEnd: the line number on end the error mark (optional)
  #   col: the column on which to mark, will utilize syntax scope to higlight
  #        the closest matching syntax element based on your code syntax
  #        (optional)
  #   colStart: column to on which to start a higlight (optional)
  #   colEnd: column to end highlight (optional)
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
      message: @formatMessage(match),
      linter: @linterName,
      range: @computeRange match
    }

  # Public: This is the method to override if you want to set a custom message
  #         not only the match.message but maybe concatenate an error|warning code
  #
  # By default it returns the message field.
  formatMessage: (match) ->
    match.message

  lineLengthForRow: (row) ->
    return @editor.lineLengthForBufferRow row

  getEditorScopesForPosition: (position) ->
    # Easy fix when line is removed before it can get lighted
    try
      @editor.displayBuffer.tokenizedBuffer.scopesForPosition position

  getGetRangeForScopeAtPosition: (innerMostScope, position) ->
    return @editor
      .displayBuffer
        .tokenizedBuffer
          .bufferRangeForScopeAtPosition(innerMostScope, position)

  # Private: This is the logic by which we automatically determine the range
  #          in the buffer that we should highlight for various combinations
  #          of line, lineStart, lineEnd, col, colStart, and colEnd values
  #          passed by the regex match.
  #
  # It is highly recommended that you utilize this logic if you are not managing
  # your own range construction logic in your linter
  #
  # match - Options used to configure linting messages
  #   message: the message to show in the linter views (required)
  #   line: the line number on which to mark error (required if not lineStart)
  #   lineStart: the line number to start the error mark (optional)
  #   lineEnd: the line number on end the error mark (optional)
  #   col: the column on which to mark, will utilize syntax scope to higlight
  #        the closest matching syntax element based on your code syntax
  #        (optional)
  #   colStart: column to on which to start a higlight (optional)
  #   colEnd: column to end highlight (optional)
  computeRange: (match) ->
    match.line ?= 0 # Assume if no line is found that it denotes a full file error.

    decrementParse = (x) ->
      Math.max 0, parseInt(x) - 1

    rowStart = decrementParse match.lineStart ? match.line
    rowEnd = decrementParse match.lineEnd ? match.line

    match.col ?=  0
    unless match.colStart
      position = new Point(rowStart, match.col)
      scopes = @getEditorScopesForPosition(position)

      while innerMostScope = scopes?.pop()
        range = @getGetRangeForScopeAtPosition(innerMostScope, position)
        return range if range?

    match.colStart ?= match.col
    colStart = decrementParse match.colStart
    colEnd = if match.colEnd?
      decrementParse match.colEnd
    else
      parseInt @lineLengthForRow(rowEnd)

    # if range has no width, nudge the start back one column
    colStart = decrementParse colStart if colStart is colEnd

    return new Range(
      [rowStart, colStart],
      [rowEnd, colEnd]
    )


module.exports = Linter
