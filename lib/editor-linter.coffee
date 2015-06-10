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

    Promise.all(@_lint(wasTriggeredOnChange, scopes)).then =>
      @_lock(wasTriggeredOnChange, false)

  # This method returns an array of promises to be used in _lint
  _lint: (wasTriggeredOnChange, scopes)->
    return @linter.linters.map (linter)=>
      return if wasTriggeredOnChange and not linter.lintOnFly
      return if (not wasTriggeredOnChange) and linter.lintOnFly
      return unless (scopes.filter (entry) -> linter.scopes.indexOf(entry) isnt -1 ).length

      new Promise((resolve)=>
        resolve(linter.lint(@editor))
      ).then(EditorLinter.validateResults).catch((error)->
        atom.notifications.addError error, {detail: error.stack, dismissible: true}
        []
      ).then =>
        if linter.scope is 'project' then @linter.messagesProject.set linter, results
        else @messages.set linter, results

        @emitter.emit 'did-update'
        @linter.view.render() if @editor is @linter.activeEditor

  # This method sets or gets the lock status of given type
  _lock: (wasTriggeredOnChange, value)->
    key = wasTriggeredOnChange ? 'inProgressFly' : 'inProgress'
    return @[key] if typeof value is 'undefined'
    @[key] = value

  @validateResults: (results)->
    if (not results) or results.constructor.name isnt 'Array'
      throw new Error "Got invalid response from Linter, Type: #{typeof results}"
    results.forEach (Result)->
      unless Result.type
        throw new Error "Missing type field on Linter Response, Got: #{Object.keys(results)}"
    results
module.exports = EditorLinter