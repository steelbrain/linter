fs = require 'fs'
temp = require 'temp'
{exec, child} = require 'child_process'

{XRegExp} = require 'xregexp'

GutterView = require './gutter-view'
HighlightsView = require './highlights-view'
_ = require 'lodash'

temp.track()

# Public: The base linter view
class LinterView

  linters: []
  totalProcessed: 0
  tempFile: ''
  messages: []
  subscriptions: []

  # Pubic: Instantiate the views
  #
  # editorView - the atom editor view on which to place highlighting and gutter
  #              annotations
  # statusBarView - shared StatusBarView between all linters
  # linters - global linter set to utilize for linting
  constructor: (editorView, statusBarView, linters) ->

    @editor = editorView.editor
    @editorView = editorView
    @gutterView = new GutterView(editorView)
    @HighlightsView = new HighlightsView(editorView)
    @statusBarView = statusBarView

    @initLinters(linters)

    @subscriptions.push atom.workspaceView.on 'pane:active-item-changed', =>
      @statusBarView.hide()
      if @editor.id is atom.workspace.getActiveEditor()?.id
        @displayStatusBar()

    @handleBufferEvents()
    @handleConfigChanges()

    @subscriptions.push @editorView.on 'editor:display-updated', =>
      @displayGutterMarkers()

    @subscriptions.push @editorView.on 'cursor:moved', =>
      @displayStatusBar()

    @lint()

  # Public: Initialize new linters (used on grammar chagne)
  #
  # linters - global linter set to utilize for linting
  initLinters: (linters) ->
    @linters = []
    grammarName = @editor.getGrammar().scopeName
    for linter in linters
      sytaxType = {}.toString.call(linter.syntax)
      if sytaxType is '[object Array]' and
      grammarName in linter.syntax or
      sytaxType is '[object String]' and
      grammarName is linter.syntax
        @linters.push(new linter(@editor))

  # Internal: register config modifications handlers
  handleConfigChanges: ->
    @subscriptions.push atom.config.observe 'linter.lintOnSave',
      (lintOnSave) => @lintOnSave = lintOnSave

    @subscriptions.push atom.config.observe 'linter.Lint on modify debounce interval (in ms)',
      (lintOnModifiedDelayMS) =>
        # If text instead of number into user config
        debounceInterval = parseInt(lintOnModifiedDelayMS)
        debounceInterval = 1000 if isNaN debounceInterval
        console.log(debounceInterval)
        @debouncedLint = (_.debounce @lint, debounceInterval).bind this

    @subscriptions.push atom.config.observe 'linter.lintOnModified',
      (lintOnModified) => @lintOnModified = lintOnModified

    @subscriptions.push atom.config.observe 'linter.showGutters',
      (showGutters) =>
        @showGutters = showGutters
        @displayGutterMarkers()

    @subscriptions.push atom.config.observe 'linter.showMessagesAroundCursor',
      (showMessagesAroundCursor) =>
        @showMessagesAroundCursor = showMessagesAroundCursor
        @displayStatusBar()

    @subscriptions.push atom.config.observe 'linter.showHightlighting',
      (showHightlighting) =>
        @showHightlighting = showHightlighting
        @displayHighlights()

  # Internal: register handlers for editor buffer events
  handleBufferEvents: =>
    buffer = @editor.getBuffer()

    @subscriptions.push buffer.on 'reloaded saved', (buffer) =>
      @lint() if @lintOnSave

    @subscriptions.push buffer.on 'destroyed', ->
      buffer.off 'reloaded saved'
      buffer.off 'destroyed'

    @subscriptions.push @editor.on 'contents-modified', =>
      @debouncedLint() if @lintOnModified

  # Public: lint the current file in the editor using the live buffer
  lint: ->
    console.log 'linter: run commands'
    @totalProcessed = 0
    @messages = []
    @gutterView.clear()
    @HighlightsView.removeHighlights()
    if @linters.length > 0
      temp.open {suffix: @editor.getGrammar().scopeName}, (err, info) =>
        info.completedLinters = 0
        fs.write info.fd, @editor.getText(), =>
          fs.close info.fd, (err) =>
            for linter in @linters
              linter.lintFile(info.path, (messages) => @processMessage(messages, info))

  # Internal: Process the messages returned by linters and render them.
  #
  # messages - An array of messages to annotate:
  #           :level  - the annotation error level ('error', 'warning')
  #           :range - The buffer range that the annotation should be placed
  processMessage: (messages, tempFileInfo) =>
    tempFileInfo.completedLinters++
    @messages = @messages.concat(messages)
    if tempFileInfo.completedLinters == @linters.length
      fs.unlink tempFileInfo.path
    @display()

  # Internal: Render all the linter messages
  display: ->
    @displayGutterMarkers()

    @displayHighlights()

    @displayStatusBar()

  # Internal: Render gutter markers
  displayGutterMarkers: ->
    if @showGutters
      @gutterView.render @messages
    else
      @gutterView.render []

  # Internal: Render code highlighting for message ranges
  displayHighlights: ->
    if @showHightlighting
      @HighlightsView.setHighlights(@messages)
    else
      @HighlightsView.removeHighlights()

  # Internal: Update the status bar for new messages
  displayStatusBar: ->
    if @showMessagesAroundCursor
      @statusBarView.render @messages, @editor
    else
      @statusBarView.render [], @editor

  # Public: remove this view and unregister all it's subscriptions
  remove: ->
    subscription.off() for subscription in @subscriptions

module.exports = LinterView
