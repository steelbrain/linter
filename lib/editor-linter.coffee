{CompositeDisposable, Emitter, Range} = require 'atom'

class EditorLinter
  constructor: (@linter, @editor) ->
    @messages = new Map # Consumed by LinterViews::render
    @_inProgress = false
    @_inProgressFly = false

    @_emitter = new Emitter
    @_subscriptions = new CompositeDisposable

    @_subscriptions.add(
      @editor.onDidSave => @lint(false)
    )
    @_subscriptions.add(
      @editor.onDidChangeCursorPosition ({newBufferPosition}) =>
        @linter.views.updateBubble(newBufferPosition)
    )
    @_subscriptions.add(
      @editor.onDidStopChanging => @lint(true) if @linter.lintOnFly
    )

  # Called on package deactivate
  destroy: ->
    @_emitter.emit 'did-destroy'
    @_subscriptions.dispose()

  onDidUpdate: (callback) ->
    @_emitter.on 'did-update', callback

  onDidDestroy: (callback) ->
    @_emitter.on 'did-destroy', callback

  lint: (wasTriggeredOnChange) ->
    return unless @editor is @linter.activeEditor
    return if @_lock(wasTriggeredOnChange)

    scopes = @editor.scopeDescriptorForBufferPosition(@editor.getCursorBufferPosition()).scopes
    scopes.push '*' # To allow global linters

    Promise.all(@_lint(wasTriggeredOnChange, scopes)).then =>
      @_lock(wasTriggeredOnChange, false)

  # This method returns an array of promises to be used in lint
  _lint: (wasTriggeredOnChange, scopes) ->
    Promises = []
    @linter.linters.forEach (linter)=>
      if @linter.lintOnFly
        return if wasTriggeredOnChange isnt linter.lintOnFly

      return unless scopes.some (entry) -> entry in linter.grammarScopes

      Promises.push new Promise((resolve) =>
        resolve(linter.lint(@editor))
      ).then(EditorLinter._validateResults).catch((error) ->
        atom.notifications.addError error.message, {detail: error.stack, dismissable: true}
        []
      ).then (results) =>
        if linter.scope is 'project' then @linter.messagesProject.set linter, results
        else @messages.set linter, results

        @_emitter.emit 'did-update'
        @linter.views.render() if @editor is @linter.activeEditor
    Promises

  # This method sets or gets the lock status of given type
  _lock: (wasTriggeredOnChange, value) ->
    key = wasTriggeredOnChange ? '_inProgressFly' : '_inProgress'
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
      result.class = result.type.toLowerCase().replace(' ', '-')
      EditorLinter._validateResults(result.trace) if result.trace
    results

module.exports = EditorLinter