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
    @linters = new Set # Values are pushed here from Main::consumeLinter

    @messages = new Messages @
    @views = new LinterViews @
    @commands = new Commands @

    @subscriptions.add atom.config.observe 'linter.lintOnFly', (value) =>
      @lintOnFly = value
    @subscriptions.add atom.project.onDidChangePaths =>
      @commands.lint()

    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      currentEditorLinter = new EditorLinter @, editor
      @editorLinters.set editor, currentEditorLinter
      @emitter.emit 'observe-editor-linters', currentEditorLinter
      currentEditorLinter.lint false
      editor.onDidDestroy =>
        currentEditorLinter.destroy()
        @editorLinters.delete editor

  serialize: -> @state

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
    @deleteMessages(linter)

  hasLinter: (linter) ->
    @linters.has(linter)

  getLinters: ->
    @linters

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
      linter.destroy()
    @views.destroy()
    @commands.destroy()
    @messages.destroy()

module.exports = Linter
