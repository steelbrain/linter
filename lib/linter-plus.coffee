Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
LinterViews = require './linter-views'
EditorLinter = require './editor-linter'
Helpers = require './helpers'
Commands = require './commands'

class Linter
  constructor: ->
    # Public Stuff
    @lintOnFly = true # A default art value, to be immediately replaced by the observe config below
    @views = new LinterViews this # Used by editor-linter to trigger views.render
    @commands = new Commands this

    # Private Stuff
    @_subscriptions = new CompositeDisposable
    @_emitter = new Emitter
    @_editorLinters = new Map
    @_messagesProject = new Map # Values set in editor-linter and consumed in views.render
    @_linters = new Set # Values are pushed here from Main::consumeLinter

    @_subscriptions.add atom.config.observe 'linter.showErrorInline', (showBubble) =>
      @views.setShowBubble(showBubble)
    @_subscriptions.add atom.config.observe 'linter.showErrorPanel', (showPanel) =>
      @views.setShowPanel(showPanel)
    @_subscriptions.add atom.config.observe 'linter.lintOnFly', (value) =>
      @lintOnFly = value
    @_subscriptions.add atom.workspace.onDidChangeActivePaneItem =>
      # Exceptions thrown here prevent switching tabs
      @commands.lint()

    @_subscriptions.add atom.workspace.observeTextEditors (editor) =>
      currentEditorLinter = new EditorLinter @, editor
      @_editorLinters.set editor, currentEditorLinter
      @_emitter.emit 'observe-editor-linters', currentEditorLinter
      currentEditorLinter.lint false
      editor.onDidDestroy =>
        currentEditorLinter.destroy()
        @_editorLinters.delete editor

  addLinter: (linter) ->
    try
      if(Helpers.validateLinter(linter))
        @_linters.add(linter)
    catch err
      atom.notifications.addError("Invalid Linter: #{err.message}", {
        detail: err.stack,
        dismissable: true
      })

  deleteLinter: (linter) ->
    return unless @hasLinter(linter)
    @_linters.delete(linter)
    if linter.scope is 'project'
      @deleteProjectMessages(linter)
    else
      @eachEditorLinter((editorLinter) ->
        editorLinter.deleteMessages(linter)
      )
    @views.render()

  hasLinter: (linter) ->
    @_linters.has(linter)

  getLinters: ->
    @_linters

  onDidChangeProjectMessages: (callback)->
    @_emitter.on 'did-change-project-messages', callback

  getProjectMessages: ->
    @_messagesProject

  setProjectMessages: (linter, messages) ->
    @_messagesProject.set(linter, Helpers.validateResults(messages))
    @_emitter.emit 'did-change-project-messages', @_messagesProject

  deleteProjectMessages: (linter) ->
    @_messagesProject.delete(linter)
    @_emitter.emit 'did-change-project-messages', @_messagesProject

  getActiveEditorLinter: ->
    return @getEditorLinter atom.workspace.getActiveTextEditor()

  getEditorLinter: (editor) ->
    return @_editorLinters.get editor

  eachEditorLinter: (callback) ->
    @_editorLinters.forEach(callback)

  observeEditorLinters: (callback) ->
    @eachEditorLinter callback
    @_emitter.on 'observe-editor-linters', callback

  deactivate: ->
    @_subscriptions.dispose()
    @eachEditorLinter (linter) ->
      linter.destroy()
    @views.destroy()
    @commands.destroy()

module.exports = Linter
