{exec, child} = require 'child_process'
fs = require 'fs'
temp = require 'temp'
{XRegExp} = require 'xregexp'
GutterView = require './gutter-view'
HighlightsView = require './highlights-view'

temp.track()
# The base class for linters.
# Subclasses must at a minimum define the attributes syntax, cmd, and regex.
class LinterView

  linters: []
  totalProcessed: 0
  tempFile: ''
  messages: []
  subscriptions: []

  # Instantiate the views
  #
  # editorView      The editor view
  constructor: (editorView, statusBarView, linters)->

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

  handleConfigChanges: () ->
    @subscriptions.push atom.config.observe 'linter.lintOnSave',
      (lintOnSave) => @lintOnSave = lintOnSave

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

  handleBufferEvents: () =>
    buffer = @editor.getBuffer()

    @subscriptions.push buffer.on 'saved', (buffer) =>
      if @lintOnSave
        if buffer.previousModifiedStatus
          console.log 'linter: lintOnSave'
          @lint()

    @subscriptions.push buffer.on 'destroyed', ->
      buffer.off 'saved'
      buffer.off 'destroyed'

    @subscriptions.push @editor.on 'contents-modified', =>
      if @lintOnModified
        console.log 'linter: lintOnModified'
        @lint()

  lint: ->
    console.log 'linter: run commands'
    @totalProcessed = 0
    @messages = []
    @gutterView.clear()
    if @linters.length > 0
      temp.open {suffix: @editor.getGrammar().scopeName}, (err, info) =>
        @tempFile = info.path
        fs.write info.fd, @editor.getText(), =>
          fs.close info.fd, (err) =>
            for linter in @linters
              linter.lintFile(info.path, @processMessage)

  processMessage: (messages)=>
    @totalProcessed++
    @messages = @messages.concat(messages)
    if @totalProcessed == @linters.length
      fs.unlink @tempFile
    @display()

  display: ->
    @displayGutterMarkers()
<<<<<<< HEAD

    @displayHighlights()

    @displayStatusBar()

  displayGutterMarkers: ->
    if @showGutters
      @gutterView.render @messages
    else
      @gutterView.render []

  displayHighlights: ->
    if @showHightlighting
      @HighlightsView.setHighlights(@messages)
    else
      @HighlightsView.removeHighlights()

  displayStatusBar: ->
    if @showMessagesAroundCursor
      @statusBarView.render @messages, @editor
    else
      @statusBarView.render [], @editor

  remove: ->
    subscription.off() for subscription in @subscriptions
=======
    @displayStatusBar()

  displayGutterMarkers: ->
    @gutterView.render @messages

  displayStatusBar: ->
    @statusBarView.render @messages, @editor
>>>>>>> origin/master

module.exports = LinterView
