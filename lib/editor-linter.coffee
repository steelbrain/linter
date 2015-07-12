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
    messages = []

    # Since I'm using filter I need a functional version of the helper.
    shouldTriggerLinter = (linter) ->
      Helpers.shouldTriggerLinter(linter, wasTriggeredOnChange, scopes)

    toRun = @linter.getLinterArray().filter(shouldTriggerLinter)
    modifyingLinters = toRun.filter((linter) -> linter.modifiesBuffer)
    linters = toRun.filter((linter) -> !linter.modifiesBuffer)

    # modifying linters must run in sequence
    modMessages = @runSequentialLinters(modifyingLinters)
    messages = @runParalellLinters(linters)

    Promise.all([modMessages, messages]).then(@storeMessages).then =>
      @lock(wasTriggeredOnChange, false)

  storeMessages: ([modMessageMap, fileMessageMap]) =>
    store = (results, linter) =>
      if linter.scope is 'project'
        @linter.setMessages(linter, results)
      else
        # Trigger event instead of updating on purpose, because
        # we want to make MessageRegistry the central message repo
        @emitter.emit('should-update', {linter, results})

    modMessageMap.forEach(store)
    fileMessageMap.forEach(store)

  # Consumes an array of linters and returns a `Map` of litners to messages
  runSequentialLinters: (linters) ->
    return linters.reduce(((promise, linter) =>
      promise.then((messageMap) =>
        @runLinter(linter).then((messages) =>
          messageMap.set(linter, messages)
          return messageMap
        )
      )
    ), Promise.resolve(new Map) )

  # Consumes an array of linters and returns a `Map` of litners to messages
  runParalellLinters: (linters) ->
    fileMessageMap = new Map()
    messages = Promise.all(linters.map((linter) =>
      @runLinter(linter).then((messages) ->
        fileMessageMap.set(linter, messages)
      )
    )).then(-> fileMessageMap)

  runLinter: (linter) ->
    return new Promise((resolve) =>
      resolve(linter.lint(@editor, Helpers))
    ).catch (error) ->
      atom.notifications.addError error.message, {detail: error.stack, dismissable: true}
      # fake a return value since the error has been handled by showing it to
      # the user
      return []

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
