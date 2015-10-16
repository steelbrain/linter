Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
LinterViews = require './linter-views'
EditorLinter = require './editor-linter'
Helpers = require './helpers'
Commands = require './commands'

class Linter
  # State is an object by default; never null or undefined
  constructor: (@state)  ->
    @state.scope ?= 'File'

    # Public Stuff
    @lintOnFly = true # A default art value, to be immediately replaced by the observe config below

    # Private Stuff
    @emitter = new Emitter
    @linters = new (require('./linter-registry'))()
    @editors = new (require('./editor-registry'))()
    @messages = new (require('./message-registry'))()
    @views = new LinterViews(state.scope, @editors)
    @commands = new Commands(this)

    @subscriptions = new CompositeDisposable(@views, @editors, @linters, @messages, @commands)

    @linters.onDidUpdateMessages ({linter, messages, editor}) =>
      @messages.set({linter, messages, editorLinter: @editors.ofTextEditor(editor)})
    @messages.onDidUpdateMessages (messages) =>
      @views.render(messages)
    @views.onDidUpdateScope (scope) =>
      @state.scope = scope

    @subscriptions.add atom.config.observe 'linter.lintOnFly', (value) =>
      @lintOnFly = value
    @subscriptions.add atom.project.onDidChangePaths =>
      @commands.lint()

    @subscriptions.add atom.workspace.observeTextEditors (editor) => @createEditorLinter(editor)

  addLinter: (linter) ->
    @linters.addLinter(linter)

  deleteLinter: (linter) ->
    return unless @hasLinter(linter)
    @linters.deleteLinter(linter)
    @deleteMessages(linter)

  hasLinter: (linter) ->
    @linters.hasLinter(linter)

  getLinters: ->
    @linters.getLinters()

  setMessages: (linter, messages) ->
    @messages.set({linter, messages})

  deleteMessages: (linter) ->
    @messages.deleteMessages(linter)

  getMessages: ->
    @messages.publicMessages

  onDidUpdateMessages: (callback) ->
    @messages.onDidUpdateMessages(callback)

  getActiveEditorLinter: ->
    @editors.ofActiveTextEditor()

  getEditorLinter: (editor) ->
    @editors.ofTextEditor(editor)

  getEditorLinterByPath: (path) ->
    @editors.ofPath(path)

  eachEditorLinter: (callback) ->
    @editors.forEach(callback)

  observeEditorLinters: (callback) ->
    @editors.observe(callback)

  createEditorLinter: (editor) ->
    return if @editors.has(editor)

    editorLinter = @editors.create(editor)
    editorLinter.onShouldUpdateBubble =>
      @views.renderBubble(editorLinter)
    editorLinter.onShouldLint (onChange) =>
      @linters.lint({onChange, editorLinter})
    editorLinter.onDidDestroy =>
      @messages.deleteEditorMessages(editorLinter)
    editorLinter.onDidCalculateLineMessages =>
      @views.updateCounts()
      @views.bottomPanel.refresh() if @state.scope is 'Line'
    @views.notifyEditorLinter(editorLinter)

  deactivate: ->
    @subscriptions.dispose()

module.exports = Linter
