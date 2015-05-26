Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'

{LinterTrace, LinterMessage, LinterError, LinterWarning} = require './messages'

class Linter

  constructor: ->
    @Emitter = new Emitter
    @Subscriptions = new CompositeDisposable
    @SubscriptionsFly = new CompositeDisposable # Fly needs to be kept separate from all others
    @Editors = new Map # I <3 ES6

  getActiveEditorLinter:->
    ActiveEditor = atom.workspace.getActiveEditor()
    return ActiveEditor unless ActiveEditor
    return @Editors.get ActiveEditor

  getEditorLinter:(Editor)->
    return @Editors.get Editor

  observeEditorLinters:(Callback)->
    @Emitter.on 'linters-observe', Callback

  onDidAddEditorLinter:(Callback)->
    @Emitter.on 'linter-add', Callback

  onDidRemoveEditorLinter:(Callback)->
    @Emitter.on 'linter-remove', Callback