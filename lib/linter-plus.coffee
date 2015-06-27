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
    @subscriptions = new CompositeDisposable
    @emitter = new Emitter
    @editorLinters = new Map
    @messagesProject = new Map # Values set in editor-linter and consumed in views.render
    @linters = new Set # Values are pushed here from Main::consumeLinter

    @subscriptions.add atom.config.observe 'linter.showErrorInline', (showBubble) =>
      @views.setShowBubble(showBubble)
    @subscriptions.add atom.config.observe 'linter.showErrorPanel', (showPanel) =>
      @views.setShowPanel(showPanel)
    @subscriptions.add atom.config.observe 'linter.underlineIssues', (underlineIssues) =>
      @views.setUnderlineIssues(underlineIssues)
    @subscriptions.add atom.config.observe 'linter.lintOnFly', (value) =>
      @lintOnFly = value
    @subscriptions.add atom.project.onDidChangePaths =>
      @commands.lint()
    @subscriptions.add atom.workspace.onDidChangeActivePaneItem =>
      @commands.lint()

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      currentEditorLinter = new EditorLinter @, editor
      @editorLinters.set editor, currentEditorLinter
      @emitter.emit 'observe-editor-linters', currentEditorLinter
      currentEditorLinter.lint false
      editor.onDidDestroy =>
        currentEditorLinter.destroy()
        @editorLinters.delete editor

  addLinter: (linter) ->
    try
      if(Helpers.validateLinter(linter))
        @linters.add(linter)
    catch err
      atom.notifications.addError("Invalid Linter: #{err.message}", {
        detail: err.stack,
        dismissable: true
      })

  deleteLinter: (linter) ->
    return unless @hasLinter(linter)
    @linters.delete(linter)
    if linter.scope is 'project'
      @deleteProjectMessages(linter)
    else
      @eachEditorLinter((editorLinter) ->
        editorLinter.deleteMessages(linter)
      )
    @views.render()

  hasLinter: (linter) ->
    @linters.has(linter)

  getLinters: ->
    @linters

  onDidChangeProjectMessages: (callback)->
    @emitter.on 'did-change-project-messages', callback

  getProjectMessages: ->
    @messagesProject

  setProjectMessages: (linter, messages) ->
    @messagesProject.set(linter, Helpers.validateResults(messages))
    @emitter.emit 'did-change-project-messages', @messagesProject
    @views.render()

  deleteProjectMessages: (linter) ->
    @messagesProject.delete(linter)
    @emitter.emit 'did-change-project-messages', @messagesProject
    @views.render()

  getActiveEditorLinter: ->
    return @getEditorLinter atom.workspace.getActiveTextEditor()

  getEditorLinter: (editor) ->
    return @editorLinters.get editor

  eachEditorLinter: (callback) ->
    @editorLinters.forEach(callback)

  observeEditorLinters: (callback) ->
    @eachEditorLinter callback
    @emitter.on 'observe-editor-linters', callback

  deactivate: ->
    @subscriptions.dispose()
    @eachEditorLinter (linter) ->
      linter.destroy()
    @views.destroy()
    @commands.destroy()

module.exports = Linter
