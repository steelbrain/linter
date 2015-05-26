Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'

{LinterTrace, LinterMessage, LinterError, LinterWarning} = require './messages'
EditorLinter = require './editor-linter'

class Linter

  constructor: ->
    @Emitter = new Emitter
    @Subscriptions = new CompositeDisposable
    @SubscriptionsFly = new CompositeDisposable # Fly needs to be kept separate from all others
    @Editors = new Map # I <3 ES6
    @Linters = new Set # I <3 ES6
    @Subscriptions.add atom.workspace.observeTextEditors (Editor) =>
      EditorLinter = new EditorLinter @, Editor
      @Emitter.emit 'linters-observe', EditorLinter

  getActiveEditorLinter:->
    ActiveEditor = atom.workspace.getActiveEditor()
    return ActiveEditor unless ActiveEditor
    return @Editors.get ActiveEditor

  getLinter:(Editor)->
    return @Editors.get Editor

  observeLinters:(Callback)->
    Callback(Linter[1]) for Linter of @Editors
    @Emitter.on 'linters-observe', Callback