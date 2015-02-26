_ = require 'lodash'
fs = require 'fs'
temp = require 'temp'
path = require 'path'
rimraf = require 'rimraf'
{CompositeDisposable, Emitter} = require 'atom'

{log, warn, moveToPreviousMessage, moveToNextMessage} = require './utils'


temp.track()

# Public: The base linter view
class LinterView

  linters: []
  totalProcessed: 0
  tempFile: ''
  messages: []

  # Pubic: Instantiate the views
  #
  # editor - the editor on which to place highlighting and gutter annotations
  # statusBarView - shared StatusBarView between all linters
  # linters - global linter set to utilize for linting
  constructor: (@editor, @statusBarView, @statusBarSummaryView, @inlineView, @allLinters = []) ->
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    unless @editor?
      warn "No editor instance on this editor"
    @markers = null

    @initLinters()

    @handleEditorEvents()
    @handleConfigChanges()

    @subscriptions.add @editor.onDidChangeCursorPosition  =>
      @updateViews()

  # Public: Initialize new linters (used on grammar change)
  #
  # linters - global linter set to utilize for linting
  initLinters: ->
    @linters = []
    grammarName = @editor.getGrammar().scopeName
    for linter in @allLinters
      if (_.isArray(linter.syntax) and grammarName in linter.syntax or
          _.isString(linter.syntax) and grammarName is linter.syntax or
          linter.syntax instanceof RegExp and linter.syntax.test(grammarName))
        @linters.push(new linter(@editor))

  # Internal: register config modifications handlers
  handleConfigChanges: ->
    @subscriptions.add atom.config.observe 'linter.lintOnSave',
      (lintOnSave) => @lintOnSave = lintOnSave

    @subscriptions.add atom.config.observe 'linter.lintOnChangeInterval',
      (lintOnModifiedDelayMS) =>
        # If text instead of number into user config
        throttleInterval = parseInt(lintOnModifiedDelayMS)
        throttleInterval = 1000 if isNaN throttleInterval
        # create throttled lint command
        @throttledLint = (_.throttle @lint, throttleInterval).bind this

    @subscriptions.add atom.config.observe 'linter.lintOnChange',
      (lintOnModified) => @lintOnModified = lintOnModified

    @subscriptions.add atom.config.observe 'linter.lintOnEditorFocus',
      (lintOnEditorFocus) => @lintOnEditorFocus = lintOnEditorFocus

    @subscriptions.add atom.config.observe 'linter.showGutters',
      (showGutters) =>
        @showGutters = showGutters
        @display()

    @subscriptions.add atom.config.observe 'linter.statusBar',
      (statusBar) =>
        @showMessagesAroundCursor = statusBar != 'None'
        @updateViews()

    @subscriptions.add atom.config.observe 'linter.showErrorInline',
      (showErrorInline) =>
        @showErrorInline = showErrorInline
        @updateViews()

    @subscriptions.add atom.config.observe 'linter.showHighlighting',
      (showHighlighting) =>
        @showHighlighting = showHighlighting
        @display()

    @subscriptions.add atom.config.observe 'linter.showInfoMessages',
      (showInfoMessages) =>
        @showInfoMessages = showInfoMessages
        @display()

    @subscriptions.add atom.config.observe 'linter.clearOnChange',
      (clearOnChange) => @clearOnChange = clearOnChange

  # Internal: register handlers for editor buffer events
  handleEditorEvents: =>
    @editor.onDidChangeGrammar =>
      @initLinters()
      @lint()

    maybeLintOnSave = => @throttledLint() if @lintOnSave
    @subscriptions.add(@editor.getBuffer().onDidReload maybeLintOnSave)
    @subscriptions.add(@editor.onDidSave maybeLintOnSave)

    @subscriptions.add @editor.onDidStopChanging =>
      if @lintOnModified
        @throttledLint()
      else if @clearOnChange and @messages.length > 0
        @messages = []
        @updateViews()
        @destroyMarkers()

    @subscriptions.add @editor.onDidDestroy =>
      @remove()

    @subscriptions.add atom.workspace.observeActivePaneItem =>
      if @editor.id is atom.workspace.getActiveTextEditor()?.id
        @throttledLint() if @lintOnEditorFocus
        @updateViews()
      else
        @statusBarView.hide()
        @statusBarSummaryView.remove()
        @inlineView.remove()

    @subscriptions.add atom.commands.add "atom-text-editor",
      "linter:lint", => @lint()

    @subscriptions.add atom.commands.add "atom-text-editor",
      "linter:next-message", => moveToNextMessage @messages, @editor

    @subscriptions.add atom.commands.add "atom-text-editor",
      "linter:previous-message", => moveToPreviousMessage @messages, @editor

  # Public: lint the current file in the editor using the live buffer
  lint: ->
    return if @linters.length is 0
    @totalProcessed = 0
    @messages = []
    @destroyMarkers()
    # create temp dir because some linters are sensitive to file names
    temp.mkdir
      prefix: 'AtomLinter'
      suffix: @editor.getGrammar().scopeName
    , (err, tmpDir) =>
      throw err if err?
      fileName = path.basename @editor.getPath()
      tempFileInfo =
        completedLinters: 0
        path: path.join tmpDir, fileName
      fs.writeFile tempFileInfo.path, @editor.getText(), (err) =>
        throw err if err?
        @linters.forEach (linter) =>  # forEach to avoid loop var capture
          linter.lintFile tempFileInfo.path, (messages) =>
            @processMessage messages, tempFileInfo, linter
        return

  # Internal: Process the messages returned by linters and render them.
  #
  # messages - An array of messages to annotate:
  #           :level  - the annotation error level ('error', 'warning', 'info')
  #           :range - The buffer range that the annotation should be placed
  processMessage: (messages, tempFileInfo, linter) =>
    log "#{linter.linterName} returned", linter, messages

    @messages = @messages.concat(messages)
    tempFileInfo.completedLinters++
    if tempFileInfo.completedLinters == @linters.length
      @display @messages
      rimraf tempFileInfo.path, (err) ->
        throw err if err?

  # Internal: Destroy all markers (and associated decorations)
  destroyMarkers: ->
    return unless @markers?
    m.destroy() for m in @markers
    @markers = null

  # Internal: Create marker from message
  createMarker: (message) ->
    marker = @editor.markBufferRange message.range, invalidate: 'never'
    klass = 'linter-' + message.level
    if @showGutters
      @editor.decorateMarker marker, type: 'line-number', class: klass
    if @showHighlighting
      @editor.decorateMarker marker, type: 'highlight', class: klass
    return marker

  # Internal: Pidgeonhole messages onto lines. Each line gets only one message,
  # the message with the highest level presides. Messages of unrecognizable
  # level (or silenced by config) will be skipped.
  sortMessagesByLine: (messages) ->
    lines = {}
    levels = ['warning', 'error']
    levels.unshift('info') if @showInfoMessages
    for message in messages
      lNum = message.line
      line = lines[lNum] || { 'level': -1 }
      msgLevel = levels.indexOf(message.level)
      continue unless msgLevel > line.level
      line.level = msgLevel
      line.msg = message
      lines[lNum] = line
    return lines

  # Internal: Render gutter icons and highlights for all linter messages.
  display: (messages = []) ->
    @destroyMarkers()

    return unless @editor.isAlive()

    unless @showGutters or @showHighlighting
      @updateViews()
      return

    @markers ?= []
    for lNum, line of @sortMessagesByLine(messages)
      marker = @createMarker(line.msg)
      @markers.push marker

    @updateViews()

  # Internal: Update the views for new messages
  updateViews: ->
    @statusBarSummaryView.render @messages, @editor
    if @showMessagesAroundCursor
      @statusBarView.render @messages, @editor
    else
      @statusBarView.render [], @editor

    if @showErrorInline
      @inlineView.render @messages, @editor
    else
      @inlineView.render [], @editor

  # Public: remove this view and unregister all its subscriptions
  remove: ->
    # TODO: when do these get destroyed as opposed to just hidden?
    @statusBarView.hide()
    @statusBarSummaryView.remove()
    @inlineView.remove()
    @subscriptions.dispose()
    l.destroy() for l in @linters
    @emitter.emit 'did-destroy'

  # Public: Invoke the given callback when the editor is destroyed.
  #
  # * `callback` {Function} to be called when the editor is destroyed.
  #
  # Returns a {Disposable} on which `.dispose()` can be called to unsubscribe.
  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback


module.exports = LinterView
