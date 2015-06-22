Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
LinterViews = require './linter-views'
EditorLinter = require './editor-linter'

class Linter
  constructor: ->
    @lintOnFly = true # A default art value, to be immediately replaced by the observe config below
    @_subscriptions = new CompositeDisposable

    @_emitter = new Emitter
    @_editorLinters = new Map
    @views = new LinterViews this # Used by editor-linter to trigger views.render
    @messagesProject = new Map # Values set in editor-linter and consumed in views.render
    @activeEditor = atom.workspace.getActiveTextEditor()
    @linters = new Set # Values are pushed here from Main::consumeLinter

    @_subscriptions.add atom.config.observe 'linter.showErrorInline', (showBubble) =>
      @views.setShowBubble(showBubble)
    @_subscriptions.add atom.config.observe 'linter.lintOnFly', (value) =>
      @lintOnFly = value
    @_subscriptions.add atom.workspace.onDidChangeActivePaneItem (editor) =>
      @activeEditor = editor
      # Exceptions thrown here prevent switching tabs
      try
        @getEditorLinter(editor)?.lint(false)
        @views.render()
      catch error
        atom.notifications.addError error.message, {detail: error.stack, dismissable: true}
    @_subscriptions.add atom.workspace.observeTextEditors (editor) =>
      currentEditorLinter = new EditorLinter @, editor
      @_editorLinters.set editor, currentEditorLinter
      @_emitter.emit 'linters-observe', currentEditorLinter
      currentEditorLinter.lint false
      editor.onDidDestroy =>
        currentEditorLinter.destroy()
        @_editorLinters.delete currentEditorLinter

  getActiveEditorLinter: ->
    return @getEditorLinter @activeEditor

  getEditorLinter: (editor) ->
    return @_editorLinters.get editor

  eachEditorLinter: (callback) ->
    @_editorLinters.forEach(callback)

  observeEditorLinters: (callback) ->
    @eachEditorLinter callback
    @_emitter.on 'linters-observe', callback

  deactivate: ->
    @_subscriptions.dispose()
    @eachEditorLinter (linter) ->
      linter.destroy()
    @views.destroy()

module.exports = Linter
