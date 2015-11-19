{CompositeDisposable, Emitter} = require 'atom'
MessageRegistry = require './message-registry'
EditorRegistry = require './editor-registry'
LinterRegistry = require './linter-registry'
IndieRegistry = require './indie-registry'
UIRegistry = require './ui-registry'
Commands = require './commands'

require './ui/message-element'

class Linter
  # State is an object by default; never null or undefined
  constructor: (@state)  ->
    @state.scope ?= 'File'

    # Public Stuff
    @lintOnFly = true # A default art value, to be immediately replaced by the observe config below

    # Private Stuff
    @emitter = new Emitter
    @linters = new LinterRegistry
    @indieLinters = new IndieRegistry()
    @editors = new EditorRegistry
    @messages = new MessageRegistry()
    @commands = new Commands(this)
    @ui = new UIRegistry()

    @subscriptions = new CompositeDisposable(@editors, @linters, @messages, @commands, @indieLinters)

    @indieLinters.observe (indieLinter) =>
      indieLinter.onDidDestroy =>
        @messages.deleteMessages(indieLinter)
    @indieLinters.onDidUpdateMessages ({linter, messages}) =>
      @messages.set({linter, messages})
    @linters.onDidUpdateMessages ({linter, messages, editor}) =>
      @messages.set({linter, messages, editorLinter: @editors.ofTextEditor(editor)})
    @messages.onDidUpdateMessages (messages) =>
      @ui.notify(messages)

    @subscriptions.add atom.config.observe 'linter.lintOnFly', (value) =>
      @lintOnFly = value
    @subscriptions.add atom.project.onDidChangePaths =>
      @commands.lint()

    @subscriptions.add atom.workspace.observeTextEditors (editor) => @createEditorLinter(editor)

  addUI: (ui) ->
    @ui.add(ui)
    ui.initialize(@editors)

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

  eachEditorLinter: (callback) ->
    @editors.forEach(callback)

  observeEditorLinters: (callback) ->
    @editors.observe(callback)

  createEditorLinter: (editor) ->
    return if @editors.has(editor)

    editorLinter = @editors.create(editor)
    editorLinter.onShouldLint (onChange) =>
      @linters.lint({onChange, editorLinter})
    editorLinter.onDidDestroy =>
      @messages.deleteEditorMessages(editorLinter)

  deactivate: ->
    @subscriptions.dispose()

module.exports = Linter
