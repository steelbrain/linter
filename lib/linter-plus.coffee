Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
LinterViews = require './linter-views'
EditorLinter = require './editor-linter'
H = require './helpers'

class Linter
  constructor: ->
    @subscriptions = new CompositeDisposable
    @lintOnFly = true

    @emitter = new Emitter
    @views = new LinterViews this
    @messagesProject = new Map
    @activeEditor = atom.workspace.getActiveTextEditor()
    @editorLinters = new Map
    @h = H
    @linters = []

    @subscriptions.add atom.config.onDidChange 'linter-plus.lintOnFly', (value) =>
      @_setLintOnFly(value)
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem (editor) =>
      @activeEditor = editor
      # Exceptions thrown here prevent switching tabs
      try
        @getLinter(editor)?.lint(false)
        @views.render()
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
    @h.genValue(@editorLinters, callback)

  observeLinters: (callback) ->
    @eachLinter callback
    @emitter.on 'linters-observe', callback

  deactivate: ->
    @subscriptions.dispose()
    @eachLinter (linter) ->
      linter.subscriptions.dispose()
    @views.deactivate()

  _setLintOnFly: (value) ->
    @eachLinter (linter) ->
      linter.setLintOnFly(value)

module.exports = Linter
