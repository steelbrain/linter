{exec, child} = require 'child_process'
{XRegExp} = require 'xregexp'
path = require 'path'
{Range, Point} = require 'atom'

# Public: The base class for linters.
# Subclasses must at a minimum define the attributes syntax, cmd, and regex.
class Linter

  # The syntax that the linter handles. May be a string or
  # list/tuple of strings. Names should be all lowercase.
  @syntax: ''

  # A string, list, tuple or callable that returns a string, list or tuple,
  # containing the command line (with arguments) used to lint.
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

  errorStream: 'stdout'

  # Public: Construct a linter passing it's base editor
  constructor: (@editor) ->
    @cwd = path.dirname(editor.getUri())

  # Private: base command construction used to execute external linter binaries
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

  # Private: Provide the node executable path for use when executing a node
  #          linter
  getNodeExecutablePath: ->
    path.join require.resolve('package'),
      '..',
      'apm/node_modules/atom-package-manager/bin/node'

  # Public: Primary entry point for a linter, executes the linter then calls
  #         processMessage in order to handle standard output
  #
  # Override this if you don't intend to use base command execution logic
  lintFile: (filePath, callback) ->
    exec @getCmd(filePath), {cwd: @cwd}, (error, stdout, stderr) =>
      if stderr
        console.warn stderr
      if @errorStream == 'stdout'
        @processMessage(stdout, callback)
      else if @errorStream == 'stderr'
        @processMessage(stderr, callback)

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
      message: match.message,
      linter: @linterName,
      range: @computeRange match
    }


  lineLengthForRow: (row) ->
    return @editor.lineLengthForBufferRow row

  getEditorScopesForPosition: (position) ->
    return @editor.displayBuffer.tokenizedBuffer.scopesForPosition(position)

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
    rowStart = parseInt(match.lineStart ? match.line) - 1
    rowEnd = parseInt(match.lineEnd ? match.line) - 1

    # some linters utilize line 0 to denote full file errors, position these
    # errors on line 1
    if (rowStart == -1)
      rowStart = rowEnd = 0

    match.col ?=  0
    unless match.colStart
      position = new Point(rowStart, match.col)
      scopes = @getEditorScopesForPosition(position)

      while innerMostScope = scopes.pop()
        range = @getGetRangeForScopeAtPosition(innerMostScope, position)
        if range?
          return range

    match.colStart ?= match.col
    colStart = parseInt(match.colStart ? 0)
    colEnd = if match.colEnd then parseInt(match.colEnd) else parseInt(@lineLengthForRow(rowEnd))
    return new Range(
      [rowStart, colStart],
      [rowEnd, colEnd]
    )


module.exports = Linter
