Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
LinterView = require './linter-view'
Panel = require './panel'
PanelView = require './panel-view'
Bottom = require './bottom'
EditorLinter = require './editor-linter'

class Linter

  constructor: ->
    @Subscriptions = new CompositeDisposable
    @LintOnFly = true

    @Emitter = new Emitter
    @View = new LinterView this
    @Bottom = new Bottom this
    @StatusBar = null
    @MessagesProject = new Map
    @ActiveEditor = atom.workspace.getActiveTextEditor()
    @EditorLinters = new Map
    @Linters = []

    @Subscriptions.add atom.views.addViewProvider Panel, (Model)->
      ( new PanelView() ).registerModel(Model)
    @Panel = new Panel this
    @PanelView = atom.views.getView @Panel

    @Subscriptions.add atom.workspace.onDidChangeActivePaneItem (Editor) =>
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