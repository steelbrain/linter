{CompositeDisposable, Emitter, Range} = require 'atom'

class EditorLinter
  constructor: (@linter, @editor) ->
    @inProgress = false
    @inProgressFly = false
    @messages = new Map

    @emitter = new Emitter
    @subscriptions = new CompositeDisposable

    @subscriptions.add(
      @editor.onDidSave => @lint(false)
    )
    @subscriptions.add(
      @editor.onDidChangeCursorPosition ({newBufferPosition}) =>
        @linter.views.updateBubble(newBufferPosition)
    )
    @subscriptions.add(
      @editor.onDidStopChanging => @lint(true) if @linter.lintOnFly
    )

  # Called on package deactivate
  destroy: ->
    @emitter.emit 'did-destroy'
    @subscriptions.dispose()

  onDidUpdate: (callback) ->
    @emitter.on 'did-update', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  lint: (wasTriggeredOnChange) ->
    return unless @editor is @linter.activeEditor
    return if wasTriggeredOnChange and not @linter.lintOnFly
    return if @_lock(wasTriggeredOnChange)
    @lint(true) unless wasTriggeredOnChange # Trigger onFly linters on save.

    scopes = @editor.scopeDescriptorForBufferPosition(@editor.getCursorBufferPosition()).scopes
    scopes.push '*' # To allow global linters

    Promise.all(@_lint(wasTriggeredOnChange, scopes)).then =>
      @_lock(wasTriggeredOnChange, false)

  # This method returns an array of promises to be used in lint
  _lint: (wasTriggeredOnChange, scopes) ->
    return @linter.linters.map (linter) =>
      return if wasTriggeredOnChange isnt linter.lintOnFly
      return unless scopes.some (entry) -> entry in linter.grammarScopes

      new Promise((resolve) =>
        resolve(linter.lint(@editor))
      ).then(EditorLinter._validateResults).catch((error) ->
        atom.notifications.addError error.message, {detail: error.stack, dismissable: true}
        []
      ).then (results) =>
        if linter.scope is 'project' then @linter.messagesProject.set linter, results
        else @messages.set linter, results

        @emitter.emit 'did-update'
        @linter.views.render() if @editor is @linter.activeEditor

  # This method sets or gets the lock status of given type
  _lock: (wasTriggeredOnChange, value) ->
    key = wasTriggeredOnChange ? 'inProgressFly' : 'inProgress'
    if typeof value is 'undefined'
      @[key]
    else
      @[key] = value

  # Checks the responses for any kind-of errors
  @_validateResults: (results) ->
    if (not results) or results.constructor.name isnt 'Array'
      throw new Error "Got invalid response from Linter, Type: #{typeof results}"
    for result in results
      unless result.type
        throw new Error "Missing type field on Linter Response, Got: #{Object.keys(result)}"
      result.range = Range.fromObject result.range if result.range?
      EditorLinter._validateResults(result.trace) if result.trace
    results
module.exports = EditorLinter