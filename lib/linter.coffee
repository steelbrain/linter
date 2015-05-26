Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
EditorLinter = require './editor-linter'

class Linter

  constructor: ->
    @View = new (require './view')(this)
    @ViewPanel = atom.workspace.addBottomPanel item: @View.root, visible: false
    @StatusBar = null
    @Messages = [] # A temp array to be used by views

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

  render: (Messages) ->
    @Messages = Messages
    # Update `LeftTile` of `StatusBar`
    @View.updateLeftTile @Messages.length

    if not @Messages.length
      @ViewPanel.hide() if @ViewPanel.isVisible()
      @View.remove()
    else
      @View.update()
      @ViewPanel.show() unless @ViewPanel.isVisible()

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