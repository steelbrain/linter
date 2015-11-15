{CompositeDisposable, Emitter} = require 'atom'
LinterViews = require './linter-views'
MessageRegistry = require './message-registry'
EditorRegistry = require './editor-registry'
LinterRegistry = require './linter-registry'
IndieRegistry = require './indie-registry'
UIRegistry = require './ui-registry'
Commands = require './commands'

class Linter
  # State is an object by default; never null or undefined
  constructor: (@state)  ->
    @state.scope ?= 'File'
    @warningShown = false

    # Public Stuff
    @lintOnFly = true # A default art value, to be immediately replaced by the observe config below

    # Private Stuff
    @emitter = new Emitter
    @linters = new LinterRegistry
    @indieLinters = new IndieRegistry()
    @editors = new EditorRegistry
    @messages = new MessageRegistry()
    @views = new LinterViews(state.scope, @editors)
    @commands = new Commands(this)
    @ui = new UIRegistry()

    @subscriptions = new CompositeDisposable(@views, @editors, @linters, @messages, @commands, @indieLinters)

    @indieLinters.observe (indieLinter) =>
      indieLinter.onDidDestroy =>
        @messages.deleteMessages(indieLinter)
    @indieLinters.onDidUpdateMessages ({linter, messages}) =>
      @messages.set({linter, messages})
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

  addUI: (key) ->
    @ui.add(key, new provider(@editors))

  deleteUI: (ui) ->
    @ui.delete(ui)

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
      if @linters.linters.size
        @linters.lint({onChange, editorLinter})
      else if not @indieLinters.indieLinters.size and not @warningShown
        @warningShown = true
        atom.notifications.addWarning('No Linter Providers Found', {detail: 'Goto atomlinter.github.io to get a list of linter providers for your favorite language', dismissable: true})
    editorLinter.onDidDestroy =>
      @messages.deleteEditorMessages(editorLinter)
    editorLinter.onDidCalculateLineMessages =>
      @views.updateCounts()
      @views.bottomPanel.refresh() if @state.scope is 'Line'
    @views.notifyEditorLinter(editorLinter)

  deactivate: ->
    @subscriptions.dispose()

module.exports = Linter
