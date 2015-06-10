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
    return unless @editor is @linter.activeEditor
    return unless @_lock(wasTriggeredOnChange)
    @lint(true) unless wasTriggeredOnChange # Trigger onFly linters on save.

    scopes = @editor.scopeDescriptorForBufferPosition(@editor.getCursorBufferPosition()).scopes
    scopes.push '*' # To allow global linters

    Promise.all(@_lint()).then =>
      @_lock(wasTriggeredOnChange, false)

  # This method returns an array of promises to be used in _lint
  _lint: ->

  # This method sets or gets the lock status of given type
  _lock: (wasTriggeredOnChange, value)->
    key = wasTriggeredOnChange ? 'inProgressFly' : 'inProgress'
    return @[key] if typeof value is 'undefined'
    @[key] = value
module.exports = EditorLinter