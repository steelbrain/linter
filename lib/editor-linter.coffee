{CompositeDisposable, Emitter} = require 'atom'

{LinterTrace, LinterError, LinterWarning} = require './messages'

class EditorLinter
  constructor: (@Linter, @Editor) ->
    @InProgress = false
    @InProgressFly = false
    @Messages = {}

    @Emitter = new Emitter
    @Subscriptions = new CompositeDisposable
    @Buffer = Editor.getBuffer()

    @Subscriptions.add(@Editor.onDidSave @lint.bind(@, false))
    @Subscriptions.add(@Editor.onDidStopChanging @lint.bind(@, true)) if @Linter.LintOnFly
    @Subscriptions.add(@Editor.onDidChangeCursorPosition ({newBufferPosition}) =>
      @Linter.Messages = @getMessages()
      @Linter.View.updateBubble newBufferPosition
    )

  lint: (OnChange) ->
    return if @progress OnChange
    return if @Editor isnt atom.workspace.getActiveTextEditor()
    @progress OnChange, true
    @lint true unless OnChange

    Scopes = @Editor.scopeDescriptorForBufferPosition(@Editor.getCursorBufferPosition()).scopes
    Promises = @lintResults OnChange, Scopes
    Promise.all(Promises).then =>
      @progress OnChange, false
    .catch ->
      console.error arguments[0].stack
      @progress OnChange, false
  lintResults: (OnChange, Scopes) ->
    Promises = []
    @Linter.Linters.forEach (Linter)=>
      return if OnChange and not Linter.lintOnFly
      return if (not OnChange) and Linter.lintOnFly
      return unless (Scopes.filter (Entry) -> Linter.scopes.indexOf(Entry) isnt -1 ).length
      Promises.push(
        (
          new Promise (Resolve)=>
            RetVal = Linter.lint(@Editor, @Buffer, {
              Error: LinterError,
              Warning: LinterWarning,
              Trace: LinterTrace
            })
            if RetVal instanceof Promise
              RetVal.then (Results)=>
                @Messages[Linter] = Results if Results instanceof Array
                Resolve()
              .catch (Error)->
                delete @Messages[Linter] # Because it's emitting errors, it's messages will never be replaced unless we do so
                atom.notifications.addError "#{Error.message}", {detail: Error.stack, dismissable: true}
                Resolve()
            else
              @Messages[Linter] = RetVal if RetVal instanceof Array
              Resolve()
        ).then =>
          Messages = @getMessages()
          @Emitter.emit 'did-update', Messages
          @Linter.Messages = Messages
          @Linter.render() if @Editor is atom.workspace.getActiveTextEditor()
      )
    Promises

  progress: (onChange, newValue) ->
    if typeof newValue is 'undefined'
      if onChange
        return @InProgressFly
      else
        return @InProgress
    else
      if onChange
        @InProgressFly = newValue
      else
        @InProgress = newValue
  getMessages: ->
    ToReturn = []
    for i, Messages of @Messages
      ToReturn = ToReturn.concat Messages
    ToReturn

  destroy: ->
    @Emitter.emit 'did-destroy'
    @Subscriptions.dispose()

  onDidUpdate: (Callback) ->
    @Emitter.on 'did-update', Callback

  onDidDestroy: (Callback) ->
    @Emitter.on 'did-destroy', Callback


module.exports = EditorLinter