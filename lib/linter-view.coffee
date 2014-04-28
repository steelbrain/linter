{exec, child} = require 'child_process'
fs = require 'fs'
temp = require 'temp'
{XRegExp} = require 'xregexp'
GutterView = require './gutter-view'

temp.track()
# The base class for linters.
# Subclasses must at a minimum define the attributes syntax, cmd, and regex.
class LinterView

  linters: []
  totalProcessed: 0
  tempFile: ''
  messages: []

  # Instantiate the views
  #
  # editorView      The editor view
  constructor: (editorView, statusBarView, linters)->

    @editor = editorView.editor
    @editorView = editorView
    @gutterView = new GutterView(editorView)
    @statusBarView = statusBarView

    @initLinters(linters)

    atom.workspaceView.on 'pane:active-item-changed', =>
      if @editor.id is atom.workspace.getActiveEditor()?.id
        @dislayStatusBar()

    @handleBufferEvents()

    @editorView.on 'editor:display-updated', =>
      @gutterView.render @messages

    @editorView.on 'cursor:moved', =>
      @statusBarView.render @messages

    @lint()

  initLinters: (linters) ->
    @linters = []
    grammarName = @editor.getGrammar().scopeName
    for linter in linters
      sytaxType = {}.toString.call(linter.syntax)
      if sytaxType is '[object Array]' && grammarName in linter.syntax or sytaxType is '[object String]' && grammarName is linter.syntax
        @linters.push(new linter())

  handleBufferEvents: () =>
    buffer = @editor.getBuffer()

    buffer.on 'saved', (buffer) =>
      if atom.config.get 'linter.lintOnSave'
        if buffer.previousModifiedStatus
          console.log 'linter: lintOnSave'
          @lint()

    buffer.on 'destroyed', ->
      buffer.off 'saved'
      buffer.off 'destroyed'

    @editor.on 'contents-modified', =>
      if atom.config.get 'linter.lintOnModified'
        console.log 'linter: lintOnModified'
        @lint()

  lint: ->
    console.log 'linter: run commands'
    @totalProcessed = 0
    @messages = []
    @gutterView.clear()
    if @linters.length > 0
      temp.open 'linter', (err, info) =>
        @tempFile = info.path
        fs.write info.fd, @editor.getText(), =>
          fs.close info.fd, (err) =>
            for linter in @linters
              linter.lintFile(info.path, @processMessage)
              # console.log 'stderr: ' + stderr
              # if error is not null
              #  console.log 'stderr: ' + error

  processMessage: (messages)=>
    @totalProcessed++
    @messages = @messages.concat(messages)
    if @totalProcessed == @linters.length
      fs.unlink @tempFile
    @dislay()

  dislay: ->
    @dislayGutterMarkers()
    @dislayStatusBar()

  dislayGutterMarkers: ->
    @gutterView.render @messages

  dislayStatusBar: ->
    @statusBarView.render @messages, @editor

module.exports = LinterView
