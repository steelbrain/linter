Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'

{LinterTrace, LinterMessage, LinterError, LinterWarning} = require './messages'
EditorLinter = require './editor-linter'

class Linter

  constructor: ->
    @Emitter = new Emitter
    @Subscriptions = new CompositeDisposable
    @EditorLinters = new Map # A map of Editor <--> Linter
    @Linters = new Set # I <3 ES6
    @Subscriptions.add atom.workspace.observeTextEditors (Editor) =>
      EditorLinter = new EditorLinter @, Editor
      @Emitter.emit 'linters-observe', EditorLinter
      Editor.onDidDestroy =>
        EditorLinter.destroy()
        @EditorLinters.delete EditorLinter

  getActiveEditorLinter:->
    ActiveEditor = atom.workspace.getActiveEditor()
    return ActiveEditor unless ActiveEditor
    return @EditorLinters.get ActiveEditor

  getLinter:(Editor)->
    return @EditorLinters.get Editor

  observeLinters:(Callback)->
    Callback(Linter[1]) for Linter of @EditorLinters
    @Emitter.on 'linters-observe', Callback

module.exports = Linter