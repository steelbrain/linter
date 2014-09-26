_ = require 'lodash'
fs = require 'fs'
temp = require 'temp'
path = require 'path'
{log, warn} = require './utils'
rimraf = require 'rimraf'


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
  constructor: (@editorView, @statusBarView, @inlineView, @linters = []) ->

    @editor = @editorView.getModel()
    unless @editor?
      warn "No editor instance on this editorView"
    @markers = null

    @initLinters(@linters)

    @subscriptions.push atom.workspaceView.on 'pane:item-removed', =>
      @statusBarView.hide()
      @inlineView.hide()

    @subscriptions.push atom.workspaceView.on 'pane:active-item-changed', =>
      if @editor.id is atom.workspace.getActiveEditor()?.id
        @updateViews()
      else
        @statusBarView.hide()
        @inlineView.hide()

    @handleBufferEvents()
    @handleConfigChanges()

    @subscriptions.push @editorView.on 'cursor:moved', =>
      @updateViews()

  # Public: Initialize new linters (used on grammar chagne)
  #
  # linters - global linter set to utilize for linting
  initLinters: (linters) ->
    @linters = []
    grammarName = @editor.getGrammar().scopeName
    for linter in linters
      if (_.isArray(linter.syntax) and grammarName in linter.syntax or
          _.isString(linter.syntax) and grammarName is linter.syntax)
        @linters.push(new linter(@editor))

  # Internal: register config modifications handlers
  handleConfigChanges: ->
    @subscriptions.push atom.config.observe 'linter.lintOnSave',
      (lintOnSave) => @lintOnSave = lintOnSave

    @subscriptions.push atom.config.observe 'linter.lintOnChangeInterval',
      (lintOnModifiedDelayMS) =>
        # If text instead of number into user config
        throttleInterval = parseInt(lintOnModifiedDelayMS)
        throttleInterval = 1000 if isNaN throttleInterval
        # create throttled lint command
        @throttledLint = (_.throttle @lint, throttleInterval).bind this

    @subscriptions.push atom.config.observe 'linter.lintOnChange',
      (lintOnModified) => @lintOnModified = lintOnModified

    @subscriptions.push atom.config.observe 'linter.lintOnEditorFocus',
      (lintOnEditorFocus) => @lintOnEditorFocus = lintOnEditorFocus

    @subscriptions.push atom.config.observe 'linter.showGutters',
      (showGutters) =>
        @showGutters = showGutters
        @display()

    @subscriptions.push atom.config.observe 'linter.showErrorInStatusBar',
      (showMessagesAroundCursor) =>
        @showMessagesAroundCursor = showMessagesAroundCursor
        @updateViews()

    @subscriptions.push atom.config.observe 'linter.showErrorInline',
      (showErrorInline) =>
        @showErrorInline = showErrorInline
        @updateViews()

    @subscriptions.push atom.config.observe 'linter.showHighlighting',
      (showHighlighting) =>
        @showHighlighting = showHighlighting
        @display()

  # Internal: register handlers for editor buffer events
  handleBufferEvents: =>
    buffer = @editor.getBuffer()

    @subscriptions.push buffer.on 'reloaded saved', (buffer) =>
      @throttledLint() if @lintOnSave

    @subscriptions.push buffer.on 'destroyed', ->
      buffer.off 'reloaded saved'
      buffer.off 'destroyed'

    @subscriptions.push @editor.on 'contents-modified', =>
      @throttledLint() if @lintOnModified

    @subscriptions.push atom.workspaceView.on 'pane:active-item-changed', =>
      if @editor.id is atom.workspace.getActiveEditor()?.id
        @throttledLint() if @lintOnEditorFocus

    atom.workspaceView.command "linter:lint", => @lint()

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
        for linter in @linters
          linter.lintFile tempFileInfo.path, (messages) =>
            @processMessage messages, tempFileInfo, linter
        return

  # Internal: Process the messages returned by linters and render them.
  #
  # messages - An array of messages to annotate:
  #           :level  - the annotation error level ('error', 'warning')
  #           :range - The buffer range that the annotation should be placed
  processMessage: (messages, tempFileInfo, linter) =>
    log "linter returned", linter, messages

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
    if @showMessagesAroundCursor
      @statusBarView.render @messages, @editor
    else
      @statusBarView.render [], @editor

    if @showErrorInline
      @inlineView.render @messages, @editorView
    else
      @inlineView.render [], @editorView


  # Public: remove this view and unregister all it's subscriptions
  remove: ->
    subscription.off() for subscription in @subscriptions

module.exports = LinterView
