{Emitter, CompositeDisposable} = require('atom')
EditorLinter = require('./editor-linter')

class EditorRegistry
  constructor: ->
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @subscriptions.add @emitter
    @editorLinters = new Map()
    @editorLintersByPath = new Map()

  create: (textEditor) ->
    editorLinter = new EditorLinter(textEditor)
    if currentPath = textEditor.getPath()
      @editorLintersByPath.set(currentPath, editorLinter)
    textEditor.onDidChangePath (path) =>
      @editorLintersByPath.delete(currentPath)
      @editorLintersByPath.set(currentPath = path, editorLinter)

    @editorLinters.set(textEditor, editorLinter)
    editorLinter.onDidDestroy =>
      @editorLinters.delete(textEditor)
    @emitter.emit('observe', editorLinter)
    return editorLinter

  has: (textEditor) ->
    return @editorLinters.has(textEditor)

  forEach: (callback) ->
    @editorLinters.forEach(callback)

  ofPath: (path) ->
    return @editorLintersByPath.get(path)

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
