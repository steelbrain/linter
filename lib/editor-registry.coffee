{Emitter, CompositeDisposable} = require('atom')
EditorLinter = require('./editor-linter')

class EditorRegistry
  constructor: ->
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @subscriptions.add @emitter
    @editorLinters = new Map()

  create: (textEditor) ->
    @editorLinters.set(textEditor, editorLinter = new EditorLinter(textEditor))
    editorLinter.onDidDestroy =>
      @editorLinters.delete(textEditor)
      editorLinter.dispose()
    @emitter.emit('observe', editorLinter)
    return editorLinter

  forEach: (callback) ->
    @editorLinters.forEach(callback)

  ofTextEditor: (editor) ->
    return @editorLinters.get(editor)

  ofActiveTextEditor: ->
    return @ofTextEditor(atom.workspace.getActiveTextEditor())

  observe: (callback) ->
    @forEach(callback)
    @emitter.on('observe', callback)

  dispose: ->
    @subscriptions.dispose()
    @editorLinters.forEach (editorLinter) ->
      editorLinter.dispose()
    @editorLinters.clear()

module.exports = EditorRegistry
