{CompositeDisposable, Emitter, Range} = require 'atom'
Helpers = require './helpers'

class EditorLinter
  constructor: (@linter, @editor) ->
    @status = true
    @messages = new Map
    @inProgress = false
    @inProgressFly = false

    if @editor is atom.workspace.getActiveTextEditor()
      @linter.views.updateLineMessages(true)

    @emitter = new Emitter
    @subscriptions = new CompositeDisposable

    @subscriptions.add(
      @editor.onDidSave => @lint(false)
    )
    @subscriptions.add(
      @editor.onDidChangeCursorPosition ({oldBufferPosition, newBufferPosition}) =>
        if newBufferPosition.row isnt oldBufferPosition.row
          @linter.views.updateLineMessages(true)
        @linter.views.renderBubble(newBufferPosition)
    )
    @subscriptions.add(
      @editor.onDidStopChanging => @lint(true) if @linter.lintOnFly
    )

  toggleStatus: ->
    @setStatus !@status

  getStatus: ->
    @status

  setStatus: (status) ->
    @status = status
    if not status
      @messages.clear()
      @linter.views.render()

  onShouldUpdate: (callback) ->
    @emitter.on 'should-update', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback

  lint: (wasTriggeredOnChange) ->
    return unless @status
    return unless @editor is atom.workspace.getActiveTextEditor()
    return unless @editor.getPath()
    return if @lock(wasTriggeredOnChange)

    scopes = @editor.scopeDescriptorForBufferPosition(@editor.getCursorBufferPosition()).scopes
    scopes.push '*' # To allow global linters
    @triggerBufferModifyingLinters.then( =>
      return Promise.all(@triggerLinters(wasTriggeredOnChange, scopes))
    ).then =>
      @lock(wasTriggeredOnChange, false)

  triggerBufferModifyingLinters: (wasTriggeredOnChange, scopes)->
    Sequence = Promise.resolve()
    @linter.getLinters().forEach (linter) =>
      return unless linter.modifiesBuffer
      return unless Helpers.shouldTriggerLinter(linter, wasTriggeredOnChange, scopes)
      Sequence = Sequence.then( =>
        linter.lint(@editor)
      ).then((results) =>
        if linter.scope is 'project'
          @linter.setMessages(linter, results)
        else
          # Trigger event instead of updating on purpose, because
          # we want to make MessageRegistry the central message repo
          @emitter.emit('should-update', {linter, results})
      )
    return Sequence

  # This method returns an array of promises to be used in lint
  triggerLinters: (wasTriggeredOnChange, scopes) ->
    Promises = []
    @linter.getLinters().forEach (linter) =>
      return unless Helpers.shouldTriggerLinter(linter, wasTriggeredOnChange, scopes)
      Promises.push new Promise((resolve) =>
        resolve(linter.lint(@editor, Helpers))
      ).then((results) =>
        if linter.scope is 'project'
          @linter.setMessages(linter, results)
        else
          # Trigger event instead of updating on purpose, because
          # we want to make MessageRegistry the central message repo
          @emitter.emit('should-update', {linter, results})
      ).catch (error) ->
        atom.notifications.addError error.message, {detail: error.stack, dismissable: true}

    Promises

  # This method sets or gets the lock status of given type
  lock: (wasTriggeredOnChange, value) ->
    key =
      if wasTriggeredOnChange
        'inProgressFly'
      else
        'inProgress'
    if typeof value is 'undefined'
      @[key]
    else
      @[key] = value

  # Called on package deactivate
  destroy: ->
    @emitter.emit 'did-destroy'
    @emitter.dispose()
    @subscriptions.dispose()

module.exports = EditorLinter
