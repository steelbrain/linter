{CompositeDisposable, Emitter, Range} = require 'atom'
Helpers = require './helpers'

class EditorLinter
  constructor: (@linter, @editor) ->
    @_messages = new Map # Consumed by LinterViews::render
    @_status = true
    @_inProgress = false
    @_inProgressFly = false

    @_emitter = new Emitter
    @_subscriptions = new CompositeDisposable

    @_subscriptions.add(
      @editor.onDidSave => @lint(false)
    )
    @_subscriptions.add(
      @editor.onDidChangeCursorPosition ({newBufferPosition}) =>
        @linter.views.updateBubble(newBufferPosition)
    )
    @_subscriptions.add(
      @editor.onDidStopChanging => @lint(true) if @linter.lintOnFly
    )

  toggleStatus: ->
    @setStatus !@_status

  getStatus: ->
    @_status

  setStatus: (status) ->
    @_status = status
    if not status
      @_messages.clear()
      @linter.views.render()

  getMessages: ->
    @_messages

  deleteMessages: (linter) ->
    @_messages.delete(linter)

  setMessages: (linter, messages) ->
    @_messages.set(linter, Helpers.validateResults(messages))

  # Called on package deactivate
  destroy: ->
    @_emitter.emit 'did-destroy'
    @_subscriptions.dispose()

  onDidUpdate: (callback) ->
    @_emitter.on 'did-update', callback

  onDidDestroy: (callback) ->
    @_emitter.on 'did-destroy', callback

  lint: (wasTriggeredOnChange) ->
    return unless @_status
    return unless @editor is atom.workspace.getActiveTextEditor()
    return unless @editor.getPath()
    return if @_lock(wasTriggeredOnChange)

    scopes = @editor.scopeDescriptorForBufferPosition(@editor.getCursorBufferPosition()).scopes
    scopes.push '*' # To allow global linters

    Promise.all(@_lint(wasTriggeredOnChange, scopes)).then =>
      @_lock(wasTriggeredOnChange, false)

  # This method returns an array of promises to be used in lint
  _lint: (wasTriggeredOnChange, scopes) ->
    Promises = []
    @linter.getLinters().forEach (linter) =>
      if @linter.lintOnFly
        return if wasTriggeredOnChange isnt linter.lintOnFly

      return unless scopes.some (entry) -> entry in linter.grammarScopes

      Promises.push new Promise((resolve) =>
        resolve(linter.lint(@editor))
      ).then((results) =>
        if linter.scope is 'project'
          @linter.setProjectMessages(linter, results)
        else
          @setMessages(linter, results)
          @linter.views.render() if @editor is atom.workspace.getActiveTextEditor()
          @_emitter.emit 'did-update'
      ).catch (error) ->
        atom.notifications.addError error.message, {detail: error.stack, dismissable: true}

    Promises

  # This method sets or gets the lock status of given type
  _lock: (wasTriggeredOnChange, value) ->
    key =
      if wasTriggeredOnChange
        '_inProgressFly'
      else
        '_inProgress'
    if typeof value is 'undefined'
      @[key]
    else
      @[key] = value

module.exports = EditorLinter
