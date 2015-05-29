Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
EditorLinter = require './editor-linter'

class Linter

  constructor: ->
    @View = new (require './view')(this)
    @ViewPanel = atom.workspace.addBottomPanel item: @View.Root, visible: false
    @StatusBar = null
    @MessagesProject = new Map
    @ActiveEditor = atom.workspace.getActiveTextEditor()

    @LintOnFly = true
    @Emitter = new Emitter
    @Subscriptions = new CompositeDisposable
    @EditorLinters = new Map # An object of Editor <--> Linter
    @Linters = [] # I </3 coffee-script
    @Subscriptions.add atom.workspace.onDidChangeActivePaneItem (Editor)=>
      @ActiveEditor = Editor
      ActiveLinter = @getActiveEditorLinter()
      return unless ActiveLinter
      ActiveLinter.lint false
    @Subscriptions.add atom.workspace.observeTextEditors (Editor) =>
      CurrentEditorLinter = new EditorLinter @, Editor
      @EditorLinters.set Editor, CurrentEditorLinter
      @Emitter.emit 'linters-observe', CurrentEditorLinter
      Editor.onDidDestroy =>
        CurrentEditorLinter.destroy()
        @EditorLinters.delete CurrentEditorLinter

  getActiveEditorLinter: ->
    return null unless @ActiveEditor
    return @EditorLinters.get @ActiveEditor

  getLinter: (Editor) ->
    return @EditorLinters.get Editor

  observeLinters: (Callback) ->
    Values = @EditorLinters.values()
    Value = Values.next()
    while not Value.done
      Callback(Value.value)
      Value = Values.next()
    @Emitter.on 'linters-observe', Callback

module.exports = Linter