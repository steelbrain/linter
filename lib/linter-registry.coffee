{Emitter, CompositeDisposable} = require('atom')
validate = require('./validate')
helpers = require('./helpers')

class LinterRegistry
  constructor: ->
    @linters = []
    @locks =
      Regular: new WeakSet
      Fly: new WeakSet
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @subscriptions.add @emitter

  getLinters: ->
    return @linters.slice() # Clone the array

  hasLinter: (linter) ->
    @linters.indexOf(linter) isnt -1

  addLinter: (linter) ->
    try
      validate.linter(linter)
      linter.deactivated = false
      @linters.push(linter)
    catch e then helpers.error(e)

  deleteLinter: (linter) ->
    return unless @hasLinter(linter)
    linter.deactivated = true
    @linters.splice(@linters.indexOf(linter), 1)

  lint: ({onChange, editorLinter}) ->
    editor = editorLinter.editor
    lockKey = if onChange then 'Fly' else 'Regular'
    return if onChange and not atom.config.get('linter.lintOnFly')
    return unless editor is atom.workspace.getActiveTextEditor()
    return unless editor.getPath()
    return if @locks[lockKey].has(editorLinter)

    @locks[lockKey].add(editorLinter)
    scopes = editor.scopeDescriptorForBufferPosition(editor.getCursorBufferPosition()).scopes
    scopes.push('*') # To allow global linters

    return @linters.reduce((promise, linter) =>
      return promise unless helpers.shouldTriggerLinter(linter, true, onChange, scopes)
      return promise.then =>
        return @triggerLinter(linter, editor, scopes)
    , Promise.resolve()).then( =>
      Promises = @linters.map (linter) =>
        return unless helpers.shouldTriggerLinter(linter, false, onChange, scopes)
        return @triggerLinter(linter, editor, scopes)
      return Promise.all(Promises)
    ).then =>
      @locks[lockKey].delete(editorLinter)

  triggerLinter: (linter, editor, scopes) ->
    return new Promise((resolve) ->
      resolve(linter.lint(editor))
    ).then((results) =>
      if results
        @emitter.emit('did-update-messages', {linter, messages: results, editor})
    ).catch((e) -> helpers.error(e))

  onDidUpdateMessages: (callback) ->
    return @emitter.on('did-update-messages', callback)

  dispose: ->
    @subscriptions.dispose()
    # Intentionally set it to empty array instead of null 'cause this would
    # disallow further execution, while still not throwing errors in current one
    @linters = []

module.exports = LinterRegistry
