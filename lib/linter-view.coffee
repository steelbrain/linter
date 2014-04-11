{exec, child} = require 'child_process'
fs = require 'fs'
temp = require 'temp'
{XRegExp} = require 'xregexp'
GutterView = require './gutter-view'
StatusBarView = require './statusbar-view'

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
  constructor: (editorView)->

    @editor = editorView.editor
    @editorView = editorView
    @gutterView = new GutterView(editorView)
    @statusBarView = new StatusBarView()
    atom.workspaceView.prependToBottom(@statusBarView)

    @handleBufferEvents()

    @editorView.on 'editor:display-updated', =>
      @gutterView.render @messages

    @editorView.on 'cursor:moved', =>
      @statusBarView.render @messages

    @lint()


  unsetLinters: ->
    @linters = []

  initLinter: (linterClass) ->
    @linters.push(new linterClass())

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

  dislayGutterMarkers: ->
    @gutterView.render @messages

module.exports = LinterView