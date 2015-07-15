Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
LinterViews = require './linter-views'
EditorLinter = require './editor-linter'
Helpers = require './helpers'
Commands = require './commands'
Messages = require './messages'
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

    @messages = new Messages @
    @views = new LinterViews @
    @commands = new Commands @

    @subscriptions.add atom.config.observe 'linter.lintOnFly', (value) =>
      @lintOnFly = value
    @subscriptions.add atom.project.onDidChangePaths =>
      @commands.lint()

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      editorLinter = new EditorLinter(editor)
      @editorLinters.set editor, editorLinter
      @emitter.emit 'observe-editor-linters', editorLinter
      editorLinter.onShouldUpdateBubble =>
        @views.renderBubble()
      editorLinter.onShouldUpdateLineMessages =>
        @views.updateLineMessages(true)
      editorLinter.onShouldLint (onChange) =>
        @linters.lint({onChange, editorLinter})
      editorLinter.onDidDestroy =>
        editorLinter.deactivate()
        @editorLinters.delete editor

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
    @messages.set(linter, messages)

  deleteMessages: (linter) ->
    @messages.delete(linter)

  getMessages: ->
    return @messages.getAll()

  onDidChangeMessages: (callback) ->
    return @messages.onDidChange(callback)

  # Classify as in sort
  onDidClassifyMessages: (callback) ->
    return @messages.onDidClassify(callback)

  onDidChangeProjectMessages: (callback) ->
    deprecate("Linter::onDidChangeProjectMessages is deprecated, use Linter::onDidChangeMessages instead")
    return @onDidChangeMessages(callback)

  getProjectMessages: ->
    deprecate("Linter::getProjectMessages is deprecated, use Linter::getMessages instead")
    return @getMessages()

  setProjectMessages: (linter, messages) ->
    deprecate("Linter::setProjectMessages is deprecated, use Linter::setMessages instead")
    return @setMessages(linter, messages)

  deleteProjectMessages: (linter) ->
    deprecate("Linter::deleteProjectMessages is deprecated, use Linter::deleteMessages instead")
    return @deleteMessages(linter)

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
      linter.deactivate()
    @views.destroy()
    @linters.deactivate()
    @commands.destroy()
    @messages.destroy()

module.exports = Linter
