{CompositeDisposable, Emitter} = require 'atom'

class EditorLinter
  constructor: (@linter, @editor)->
    @inProgress = false
    @inProgressFly = false
    @messages = new Map

    @emitter = new Emitter
    @subscriptions = new CompositeDisposable

    @subscriptions.add(
      @editor.onDidSave => @lint(false)
    )
    @subscriptions.add(
      @editor.onDidChangeCursorPosition ({newBufferPosition}) => @linter.bubble?.update(newBufferPosition)
    )
    return unless @linter.lintOnFly
    @subscriptions.add(
      @editor.onDidStopChanging => @lint(true)
    )
  lint: (wasTriggeredOnChange)->
module.exports = EditorLinter