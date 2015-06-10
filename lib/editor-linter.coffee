{CompositeDisposable, Emitter} = require 'atom'

validateResults = (results) ->
  unless results instanceof Array
    throw new Error("Invalid linter response. found typeof " + (typeof results))

  for r in results
    unless r.type?
      throw new Error('Missing "type". found keys', Object.keys(r))

  return results

showError = (error) ->
  atom.notifications.addError "#{error.message}", {detail: error.stack, dismissable: true}
  return []

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
      @linter.bubble?.update newBufferPosition
    )

  lint: (onChange) ->
    return if @editor isnt @linter.activeEditor

    # When linting is triggered on save, we also trigger the onFly linters
    if not onChange
      @lint true

    @_promiseLock(onChange, =>
      scopes = @editor.scopeDescriptorForBufferPosition(@editor.getCursorBufferPosition()).scopes
      scopes.push '*' # Ensure that everything can be linted with a wildcard.
      return Promise.all(@lintResults(onChange, scopes))
    )
    undefined

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
      .catch(showError)
      .then((results) =>
        if linter.scope is 'project' then @linter.messagesProject.set linter, results
        else @messages.set linter, results

        @emitter.emit 'did-update'
        @linter.view.render() if @editor is @linter.activeEditor
      )

  _promiseLock: (onChange, callback) ->
    key = if onChange then 'inProgressFly' else 'inProgress'

    return if @[key]
    @[key] = true
    callback().catch(showError).then( =>
      @[key] = false
    )

  destroy: ->
    @emitter.emit 'did-destroy'
    @subscriptions.dispose()

  onDidUpdate: (callback) ->
    @emitter.on 'did-update', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback


module.exports = EditorLinter
