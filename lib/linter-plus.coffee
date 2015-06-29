Path = require 'path'
{CompositeDisposable, Emitter} = require 'atom'
LinterViews = require './linter-views'
EditorLinter = require './editor-linter'
Helpers = require './helpers'
Commands = require './commands'
Messages = require './messages'

class Linter
  constructor:(@state)  ->
    @state ?= {}

    # Public Stuff
    @lintOnFly = true # A default art value, to be immediately replaced by the observe config below

    # Private Stuff
    @subscriptions = new CompositeDisposable
    @emitter = new Emitter
    @editorLinters = new Map
    @linters = new Set # Values are pushed here from Main::consumeLinter

    @messages = new Messages(this)
    @views = new LinterViews @state, this
    @commands = new Commands this

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

    @subscriptions.add atom.config.onDidChange 'linter.showErrorTabLine', =>
      @views.updateTabs()
    @subscriptions.add atom.config.onDidChange 'linter.showErrorTabFile', =>
      @views.updateTabs()
    @subscriptions.add atom.config.onDidChange 'linter.showErrorTabProject', =>
      @views.updateTabs()

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

  deleteMessages: (linter, messages) ->
    @messages.delete(linter)

  getMessages: ->
    return @messages.get()

  onDidChangeMessages: (callback)->
    return @messages.onDidChange(callback)

  onDidChangeProjectMessages: (callback) ->
    console.warn("Linter::onDidChangeProjectMessages is deprecated, use Linter::onDidChangeMessages instead")
    return @onDidChangeMessages(callback)

  getProjectMessages: ->
    console.warn("Linter::getProjectMessages is deprecated, use Linter::getMessages instead")
    return @getMessages()

  setProjectMessages: (linter, messages) ->
    console.warn("Linter::setProjectMessages is deprecated, use Linter::setMessages instead")
    return @setMessages(linter, messages)

  deleteProjectMessages: (linter) ->
    console.warn("Linter::deleteProjectMessages is deprecated, use Linter::deleteMessages instead")
    return @setMessages(linter, messages)

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
    @messages.clear()
    @subscriptions.dispose()
    @eachEditorLinter (linter) ->
      linter.destroy()
    @views.destroy()
    @commands.destroy()

module.exports = Linter
