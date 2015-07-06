fs = require 'fs'
path = require 'path'
{CompositeDisposable, Range, Point, BufferedProcess} = require 'atom'
XRegExp = null
{deprecate} = require('grim')

# These are NOOPs in linter-plus
log = -> undefined
warn = -> undefined

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

  # Base options
  baseOptions: ['executionTimeout']

  # Child options
  options: []

  # Public: Construct a linter passing it's base editor
  constructor: (@editor) ->
    deprecate('AtomLinter v0.X.Y API has been deprecated.
      Please refer to the Linter docs to update and the latest API:
      https://github.com/AtomLinter/Linter/wiki/Migrating-to-the-new-API')

    @cwd = path.dirname(@editor.getPath())

    @subscriptions = new CompositeDisposable

    # Load options from `linter`
    @observeOption('linter', option) for option in @baseOptions

    # Load options from `linter-child`
    @observeOption("linter-#{@linterName}", option) for option in @options

    @_statCache = new Map()

  observeOption: (prefix, option) ->
    callback = @updateOption.bind(this, prefix, option)
    @subscriptions.add atom.config.observe "#{prefix}.#{option}", callback

  updateOption: (prefix, option) =>
    @[option] = atom.config.get "#{prefix}.#{option}"
    log "Updating `#{prefix}` #{option} to #{@[option]}"

  destroy: ->
    @subscriptions.dispose()

  # Private: Exists mostly so we can use statSync without slowing down linting.
  # TODO: Do this at constructor time?
  _cachedStatSync: (path) ->
    stat = @_statCache.get path
    unless stat
      stat = fs.statSync path
      @_statCache.set(path, stat)
    stat

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
      if /@tempdir/i.test(cmd_item)
        return cmd_item.replace(/@tempdir/gi, path.dirname(filePath))
      else
        return cmd_item

    log 'command and arguments', cmd_list

    {
      command: cmd_list[0],
      args: cmd_list.slice(1)
    }

  getReportFilePath: (filePath) ->
    path.join(path.dirname(filePath), @reportFilePath)

  # Private: Provide the node executable path for use when executing a node
  #          linter
  getNodeExecutablePath: ->
    path.join atom.packages.getApmPath(), '..', 'node'

  linterNotFound: ->
    notFoundMessage = "Linting has been halted.
        Please install the linter binary or disable the linter plugin depending on it.
        Make sure to reload Atom to detect changes"
    atom.notifications.addError "
      The linter binary '#{@linterName}' cannot be found.",
      {detail: notFoundMessage, dismissable: true}

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
    exited = false

    stdout = (output) ->
      log 'stdout', output
      dataStdout.push output

    stderr = (output) ->
      warn 'stderr', output
      dataStderr.push output

    exit = (exitCode) =>
      exited = true
      if exitCode is 8
        # Exit code of node when the file you execute doesn't exist
        return @linterNotFound()
      switch @errorStream
        when 'file'
          reportFilePath = @getReportFilePath(filePath)
          if fs.existsSync reportFilePath
            data = fs.readFileSync(reportFilePath)
        when 'stdout' then data = dataStdout.join('')
        else data = dataStderr.join('')
      @processMessage data, callback

    {command, args, options} = @beforeSpawnProcess(command, args, options)
    log("beforeSpawnProcess:", command, args, options)

    SpawnedProcess = new BufferedProcess({command, args, options,
                                  stdout, stderr, exit})
    SpawnedProcess.onWillThrowError (err) =>
      return unless err?
      if err.error.code is 'ENOENT'
        # Add defaults because the new linter doesn't include these configs
        @linterNotFound()

    # Kill the linter process if it takes too long
    if @executionTimeout > 0
      setTimeout =>
        return if exited
        SpawnedProcess.kill()
        warn "command `#{command}` timed out after #{@executionTimeout} ms"
      , @executionTimeout

  # Public: Gives subclasses a chance to read or change the command, args and
  #         options, before creating new BufferedProcess while lintFile.
  #   command: a string of executablePath
  #   args: an array of string arguments
  #   options: an object of options (has cwd field)
  # Returns an object of {command, args, options}
  # Override this if you want to read or change these arguments
  beforeSpawnProcess: (command, args, options) ->
    {command: command, args: args, options: options}

  # Private: process the string result of a linter execution using the regex
  #          as the message builder
  #
  # Override this in order to handle message processing in a different manner
  # for instance if the linter returns json or xml data
  processMessage: (message, callback) ->
    messages = []
    XRegExp ?= require('xregexp').XRegExp
    @MessageRegexp ?= XRegExp @regex, @regexFlags
    XRegExp.forEach message, @MessageRegexp, (match, i) =>
      msg = @createMessage match
      messages.push msg if msg.range?
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
    else if match.info
      level = 'info'
    else
      level = match.level or @defaultLevel

    # If no line/col is found, assume a full file error
    # TODO: This conflicts with the docs above that say line is required :(
    match.line ?= 0
    match.col ?= 0

    return {
      # TODO: It's confusing that line & col are here since they duplicate info
      # that's present in the value for range. Consider deprecating line & col
      # since they're less general than range.
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
    text = @editor.lineTextForBufferRow row
    return text?.length or 0

  getEditorScopesForPosition: (position) ->
    try
      # return a copy in case it gets mutated (hint: it does)
      @editor.displayBuffer.tokenizedBuffer.scopesForPosition(position).slice()
    catch
      # this can throw if the line has since been deleted
      []

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

    decrementParse = (x) ->
      Math.max 0, parseInt(x) - 1

    rowStart = decrementParse match.lineStart ? match.line
    rowEnd = decrementParse match.lineEnd ? match.line ? rowStart

    # if this message purports to be from beyond the maximum line count,
    # ignore it
    if rowEnd >= @editor.getLineCount()
      log "ignoring #{match} - it's longer than the buffer"
      return null

    unless match.colStart
      position = new Point(rowStart, match.col)
      scopes = @getEditorScopesForPosition(position)

      while innerMostScope = scopes.pop()
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
