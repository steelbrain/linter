{CompositeDisposable, Emitter} = require 'atom'

validateResults = (results) ->
  unless results instanceof Array
    throw new Error("Invalid linter response. found typeof " + (typeof results))

  for r in results
    unless r.type?
      throw new Error('Missing "type". found keys', Object.keys(r))

  return results

class EditorLinter
  constructor: (@linter, @editor) ->
    @inProgress = false
    @inProgressFly = false
    @messages = new Map

    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @buffer = @editor.getBuffer()

    @subscriptions.add(@editor.onDidSave @lint.bind(@, false))
    @subscriptions.add(@editor.onDidStopChanging @lint.bind(@, true)) if @linter.lintOnFly
    @subscriptions.add(@editor.onDidChangeCursorPosition ({newBufferPosition}) =>
      @linter.bubble.update newBufferPosition
    )

  lint: (onChange) ->
    return if @progress onChange
    return if @editor isnt @linter.activeEditor
    @progress onChange, true
    @lint true unless onChange

    scopes = @editor.scopeDescriptorForBufferPosition(@editor.getCursorBufferPosition()).scopes
    scopes.push '*' # Ensure that everything can be linted with a wildcard.
    promises = @lintResults onChange, scopes
    Promise.all(promises).then =>
      @progress onChange, false
    .catch ->
      console.error arguments[0].stack
      @progress onChange, false
  lintResults: (onChange, scopes) ->
    return @linter.linters.map (linter) =>
      return if onChange and not linter.lintOnFly
      return if (not onChange) and linter.lintOnFly
      return unless (scopes.filter (entry) -> linter.scopes.indexOf(entry) isnt -1 ).length

      return new Promise((resolve) =>
        # Using this callback style instead of `Promise.resolve` means we'll
        # catch any exceptions thrown by `linter.lint`
        resolve(linter.lint(@editor, @buffer))
      ).then(validateResults)
      .then((results) =>
        if linter.scope is 'project' then @linter.messagesProject.set linter, results
        else @messages.set linter, results
      ).catch((error) =>
        if linter.scope is 'project' then @linter.messagesProject.delete linter
        else @messages.delete linter
        atom.notifications.addError "#{error.message}", {detail: error.stack, dismissable: true}
      ).then(=> # finally
        @emitter.emit 'did-update'
        @linter.view.render() if @editor is @linter.activeEditor
      )

  progress: (onChange, newValue) ->
    if typeof newValue is 'undefined'
      if onChange
        return @inProgressFly
      else
        return @inProgress
    else
      if onChange
        @inProgressFly = newValue
      else
        @inProgress = newValue

  destroy: ->
    @emitter.emit 'did-destroy'
    @subscriptions.dispose()

  onDidUpdate: (callback) ->
    @emitter.on 'did-update', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback


module.exports = EditorLinter
