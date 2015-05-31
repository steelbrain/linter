Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
LinterView = require './linter-view'
Bubble = require './bubble'
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
    @Bubble = new Bubble this
    @StatusBar = null
    @MessagesProject = new Map
    @ActiveEditor = atom.workspace.getActiveTextEditor()
    @EditorLinters = new Map
    @Linters = []

    @Subscriptions.add atom.views.addViewProvider Panel, (Model)=>
      @PanelView = ( new PanelView() ).initialize(Model, @)
    @Panel = new Panel this
    @PanelModal = atom.workspace.addBottomPanel item: @Panel, visible: false

    @Subscriptions.add atom.workspace.onDidChangeActivePaneItem (Editor) =>
      @ActiveEditor = Editor
      ActiveLinter = @getActiveEditorLinter()
      return unless ActiveLinter
      ActiveLinter.lint false
    @Subscriptions.add atom.workspace.observeTextEditors (Editor) =>
      CurrentEditorLinter = new EditorLinter @, Editor
      @EditorLinters.set Editor, CurrentEditorLinter
      @Emitter.emit 'linters-observe', CurrentEditorLinter
      CurrentEditorLinter.lint false
      Editor.onDidDestroy =>
        CurrentEditorLinter.destroy()
        @EditorLinters.delete CurrentEditorLinter

  getActiveEditorLinter: ->
    return null unless @ActiveEditor
    return @EditorLinters.get @ActiveEditor

  getLinter: (Editor) ->
    return @EditorLinters.get Editor

  eachLinter: (Callback)->
    Values = @EditorLinters.values()
    Value = Values.next()
    while not Value.done
      Callback(Value.value)
      Value = Values.next()
  observeLinters: (Callback) ->
    @eachLinter Callback
    @Emitter.on 'linters-observe', Callback

  deactivate: ->
    @Subscriptions.dispose()
    @Panel.removeDecorations()
    @Bottom.remove()
    @Bubble.remove()
    @eachLinter (Linter)->
      Linter.Subscriptions.dispose()
    @PanelModal.destroy()

module.exports = Linter