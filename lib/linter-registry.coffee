{Emitter} = require('atom')
validate = require('./validate')
helpers = require('./helpers')

class LinterRegistry
  constructor: ->
    @linters = []
    @locks =
      Regular: new WeakSet
      Fly: new WeakSet
    @emitter = new Emitter

  getLinters: ->
    return @linters.slice() # Clone the array

  hasLinter: (linter) ->
    @linters.indexOf(linter) isnt -1

  addLinter: (linter) ->
    try
      validate.linter(linter)
      @linters.push(linter)
    catch e then helpers.error(e)

  deleteLinter: (linter) ->
    return unless @hasLinter(linter)
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

    # Confusing code ahead, proceed with caution :P
    return @linters.reduce((promise, linter) =>
      if helpers.shouldTriggerLinter(linter, true, onChange, scopes)
        return promise.then(-> linter.lint(editor)).then((vals) =>
          if vals then @emitter.emit('did-update-messages', {linter, messages: vals, editor})
        ).catch (e) -> helpers.error(e)
      else return promise
    , Promise.resolve()).then( =>
      Promises = []
      @linters.forEach (linter) =>
        return unless helpers.shouldTriggerLinter(linter, false, onChange, scopes)
        try result = linter.lint(editor) catch e then return helpers.error(e)
        unless result instanceof Promise
          result = Promise.resolve(result)
        result.then (vals) =>
          if vals then @emitter.emit('did-update-messages', {linter, messages: vals, editor})
      return Promise.all(Promises)
    ).then =>
      @locks[lockKey].delete(editorLinter)

  onDidUpdateMessages: (callback) ->
    return @emitter.on('did-update-messages', callback)

  deactivate: ->
    @emitter.dispose()
    @linters = []

module.exports = LinterRegistry
