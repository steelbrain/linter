_ = require 'lodash'
fs = require 'fs'
temp = require 'temp'
path = require 'path'
rimraf = require 'rimraf'
{CompositeDisposable, Emitter} = require 'event-kit'

{log, warn} = require './utils'


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

  # Public: Initialize new linters (used on grammar chagne)
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

  # Internal: register handlers for editor buffer events
  handleEditorEvents: =>
    @editor.onDidChangeGrammar =>
      @initLinters()
      @lint()

    maybeLintOnSave = => @throttledLint() if @lintOnSave
    @subscriptions.add(@editor.getBuffer().onDidReload maybeLintOnSave)
    @subscriptions.add(@editor.onDidSave maybeLintOnSave)

    @subscriptions.add @editor.onDidStopChanging =>
      @throttledLint() if @lintOnModified

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

    atom.commands.add "atom-text-editor",
      "linter:lint", => @lint()

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
  #           :level  - the annotation error level ('error', 'warning')
  #           :range - The buffer range that the annotation should be placed
  processMessage: (messages, tempFileInfo, linter) =>
    log "#{linter.linterName} returned", linter, messages

    tempFileInfo.completedLinters++
    if tempFileInfo.completedLinters == @linters.length
      rimraf tempFileInfo.path, (err) ->
        throw err if err?

    @messages = @messages.concat(messages)
    @display()

  # Internal: Destroy all markers (and associated decorations)
  destroyMarkers: ->
    return unless @markers?
    m.destroy() for m in @markers
    @markers = null

  # Internal: Render all the linter messages
  display: ->
    @destroyMarkers()

    return unless @editor.isAlive()

    if @showGutters or @showHighlighting
      @markers ?= []
      for message in @messages
        klass = if message.level == 'error'
          'linter-error'
        else if message.level == 'warning'
          'linter-warning'
        continue unless klass?  # skip other messages

        marker = @editor.markBufferRange message.range, invalidate: 'never'
        @markers.push marker

        if @showGutters
          @editor.decorateMarker marker, type: 'gutter', class: klass

        if @showHighlighting
          @editor.decorateMarker marker, type: 'highlight', class: klass

    @updateViews()

  # Internal: Update the views for new messages
  updateViews: ->
    @statusBarSummaryView.render @messages
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
