Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
EditorLinter = require './editor-linter'
Utils = require './utils'

class Linter

  constructor: ->
    @View = new (require './view')(this)
    @ViewPanel = atom.workspace.addBottomPanel item: @View.root, visible: false
    @StatusBar = null
    @MessagesGlobal = new Map
    @Messages = [] # A temp array to be used by views
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

  render: ->
    # Update `LeftTile` of `StatusBar`
    @View.updateLeftTile @Messages.length

    if not @Messages.length
      @ViewPanel.hide() if @ViewPanel.isVisible()
      @View.remove()
    else
      @View.update()
      @ViewPanel.show() unless @ViewPanel.isVisible()

  getActiveEditorLinter: ->
    return null unless @ActiveEditor
    return @EditorLinters.get @ActiveEditor

  getLinter: (Editor) ->
    return @EditorLinters.get Editor

  observeLinters: (Callback) ->
    Utils.values(@EditorLinters).forEach (Entry)->
      Callback(Entry[1])
    @Emitter.on 'linters-observe', Callback

module.exports = Linter