Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
LinterViews = require './linter-views'
EditorLinter = require './editor-linter'
Helpers = require './helpers'
Commands = require './commands'
{deprecate} = require 'grim'

class Linter
  # State is an object by default; never null or undefined
  constructor:(@state)  ->
    @state.scope ?= 'File'

    # Public Stuff
    @lintOnFly = true # A default art value, to be immediately replaced by the observe config below

    # Private Stuff
    @subscriptions = new CompositeDisposable
    @emitter = new Emitter
    @editorLinters = new Map
    @linters = new (require('./linter-registry'))()
    @messages = new (require('./messages'))()
    @views = new LinterViews @
    @commands = new Commands @

    @subscriptions.add @linters.onDidUpdateMessages (info) =>
      @messages.set(info)
    @subscriptions.add @messages.onDidUpdateMessages (messages) =>
      @views.render(messages)

    @subscriptions.add atom.config.observe 'linter.lintOnFly', (value) =>
      @lintOnFly = value
    @subscriptions.add atom.project.onDidChangePaths =>
      @commands.lint()

    @subscriptions.add atom.workspace.observeTextEditors (editor) => @createEditorLinter(editor)

  serialize: -> @state

  addLinter: (linter) ->
    @linters.addLinter(linter)

  deleteLinter: (linter) ->
    @linters.deleteLinter(linter)

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

  onDidChangeMessages: (callback) ->
    @messages.onDidUpdateMessages(callback)

  onDidChangeProjectMessages: (callback) ->
    deprecate("Linter::onDidChangeProjectMessages is deprecated, use Linter::onDidChangeMessages instead")
    @onDidChangeMessages(callback)

  getProjectMessages: ->
    deprecate("Linter::getProjectMessages is deprecated, use Linter::getMessages instead")
    @getMessages()

  setProjectMessages: (linter, messages) ->
    deprecate("Linter::setProjectMessages is deprecated, use Linter::setMessages instead")
    @setMessages(linter, messages)

  deleteProjectMessages: (linter) ->
    deprecate("Linter::deleteProjectMessages is deprecated, use Linter::deleteMessages instead")
    @deleteMessages(linter)

  getActiveEditorLinter: ->
    @getEditorLinter atom.workspace.getActiveTextEditor()

  getEditorLinter: (editor) ->
    @editorLinters.get editor

  eachEditorLinter: (callback) ->
    @editorLinters.forEach(callback)

  observeEditorLinters: (callback) ->
    @eachEditorLinter callback
    @emitter.on 'observe-editor-linters', callback

  createEditorLinter: (editor) ->
    editorLinter = new EditorLinter(editor)
    @editorLinters.set editor, editorLinter
    @emitter.emit 'observe-editor-linters', editorLinter
    editorLinter.onShouldUpdateBubble =>
      @views.renderBubble()
    editorLinter.onShouldUpdateLineMessages =>
      @views.renderLineMessages(true)
    editorLinter.onShouldLint (onChange) =>
      @linters.lint({onChange, editorLinter})
    editorLinter.onDidDestroy =>
      editorLinter.deactivate()
      @editorLinters.delete(editor)
      @messages.deleteEditorMessages(editor)

  deactivate: ->
    @subscriptions.dispose()
    @eachEditorLinter (linter) ->
      linter.deactivate()
    @views.destroy()
    @linters.deactivate()
    @commands.destroy()
    @messages.deactivate()

module.exports = Linter
