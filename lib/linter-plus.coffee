Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
LinterView = require './linter-view-manager'
LinterViews = require './linter-views'
Bubble = require './bubble'
Panel = require './panel'
PanelView = require './views/panel'
EditorLinter = require './editor-linter'
H = require './h'

class Linter

  constructor: ->
    @subscriptions = new CompositeDisposable
    @lintOnFly = true

    @emitter = new Emitter
    @view = new LinterView this
    @views = new LinterViews this
    @statusBar = null
    @messagesProject = new Map
    @activeEditor = atom.workspace.getActiveTextEditor()
    @editorLinters = new Map
    @h = new H
    @linters = []

    @subscriptions.add atom.config.observe 'linter.showErrorInline', (showErrorInline) =>
      if showErrorInline
        @bubble = new Bubble this
      else
        @bubble?.remove()
        @bubble = null

    @subscriptions.add atom.views.addViewProvider Panel, (model) =>
      @panelView = ( new PanelView() ).initialize(model, @)
    @panel = new Panel this
    @panelModal = atom.workspace.addBottomPanel item: @panel, visible: false

    @subscriptions.add atom.workspace.onDidChangeActivePaneItem (editor) =>
      @activeEditor = editor
      # Exceptions thrown here prevent switching tabs
      try
        @getLinter(editor)?.lint(false)
        @view.render()
      catch error
        atom.notifications.addError error.message, {detail: error.stack, dismissable: true}
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      currentEditorLinter = new EditorLinter @, editor
      @editorLinters.set editor, currentEditorLinter
      @emitter.emit 'linters-observe', currentEditorLinter
      currentEditorLinter.lint false
      editor.onDidDestroy =>
        currentEditorLinter.destroy()
        @editorLinters.delete currentEditorLinter

  getActiveEditorLinter: ->
    return @getLinter(@activeEditor)

  getLinter: (editor) ->
    return @editorLinters.get editor

  eachLinter: (callback) ->
    values = @editorLinters.values()
    value = values.next()
    while not value.done
      callback(value.value)
      value = values.next()

  observeLinters: (callback) ->
    @eachLinter callback
    @emitter.on 'linters-observe', callback

  deactivate: ->
    @subscriptions.dispose()
    @panel.removeDecorations()
    @bubble?.remove()
    @eachLinter (linter) ->
      linter.subscriptions.dispose()
    @panelModal.destroy()
    @views.deactivate()

module.exports = Linter
