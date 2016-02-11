{CompositeDisposable, Emitter} = require 'atom'
{MessageRegistry} = require './message-registry'
EditorRegistry = require './editor-registry'
LinterRegistry = require './linter-registry'
IndieRegistry = require './indie-registry'
UIRegistry = require './ui-registry'
Commands = require './commands'

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
    @commands = new Commands()
    @ui = new UIRegistry()

    @subscriptions = new CompositeDisposable(@editors, @linters, @messages, @commands, @indieLinters)

    @indieLinters.observe (indieLinter) =>
      indieLinter.onDidDestroy =>
        @messages.deleteByLinter(indieLinter)
    @indieLinters.onDidUpdateMessages ({linter, messages}) =>
      @messages.set({messages, linter, buffer: null})
    @linters.onDidUpdateMessages ({messages, linter, buffer}) =>
      @messages.set({messages, linter, buffer})
    @linters.onDidBeginLinting ({linter, filePath}) =>
      @ui.didBeginLinting(linter, filePath)
    @linters.onDidFinishLinting ({linter, filePath}) =>
      @ui.didFinishLinting(linter, filePath)
    @messages.onDidUpdateMessages (messages) =>
      @ui.didCalculateMessages(messages)

    @subscriptions.add atom.config.observe 'linter.lintOnFly', (value) =>
      @lintOnFly = value

    @subscriptions.add atom.workspace.observeTextEditors (editor) => @createEditorLinter(editor)
    @commands.onShouldLint =>
      @getActiveEditorLinter()?.lint()
    @commands.onShouldToggleActiveEditor =>
      activeLinter = @getActiveEditorLinter()
      if activeLinter
        activeLinter.dispose()
      else
        @createEditorLinter(atom.workspace.getActiveTextEditor())

    # Defer execution because onDidChangePaths is added on editor init,
    # we don't want to lint until editor is initialized
    setImmediate =>
      @subscriptions.add atom.project.onDidChangePaths =>
        @commands.lint()

  addUI: (ui) ->
    @ui.add(ui)

  deleteUI: (ui) ->
    @ui.delete(ui)

  addLinter: (linter) ->
    @linters.addLinter(linter)

  deleteLinter: (linter) ->
    return unless @hasLinter(linter)
    @linters.deleteLinter(linter)
    @messages.deleteByLinter(linter)

  hasLinter: (linter) ->
    @linters.hasLinter(linter)

  getLinters: ->
    @linters.getLinters()

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
      @linters.lint({onChange, editor})
    editorLinter.onDidDestroy =>
      @messages.deleteByBuffer(editor.getBuffer())

  deactivate: ->
    @subscriptions.dispose()

module.exports = Linter
