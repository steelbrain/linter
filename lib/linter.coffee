Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
EditorLinter = require './editor-linter'

class Linter

  constructor: ->
    @LintOnFly = true
    @Emitter = new Emitter
    @Subscriptions = new CompositeDisposable
    @EditorLinters = {} # A map of Editor <--> Linter
    @Linters = [] # I <3 ES6
    @Subscriptions.add atom.workspace.observeTextEditors (Editor) =>
      CurrentEditorLinter = new EditorLinter @, Editor
      @Emitter.emit 'linters-observe', CurrentEditorLinter
      Editor.onDidDestroy =>
        CurrentEditorLinter.destroy()
        delete @EditorLinters[ CurrentEditorLinter ]

  getActiveEditorLinter:->
    ActiveEditor = atom.workspace.getActiveEditor()
    return ActiveEditor unless ActiveEditor
    return @EditorLinters[ ActiveEditor ]

  getLinter:(Editor)->
    return @EditorLinters[ Editor ]

  observeLinters:(Callback)->
    Callback(Linter) for Linter of @EditorLinters
    @Emitter.on 'linters-observe', Callback

module.exports = Linter