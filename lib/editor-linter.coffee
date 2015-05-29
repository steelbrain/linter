{CompositeDisposable, Emitter} = require 'atom'
Utils = require './utils'

class EditorLinter
  constructor: (@Linter, @Editor) ->
    @InProgress = false
    @InProgressFly = false
    @Messages = new Map

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
            RetVal = Linter.lint(@Editor, @Buffer, OnChange)
            if RetVal instanceof Promise
              RetVal.then (Results)=>
                if Results instanceof Array
                  if Linter.scope is 'global' then @Linter.MessagesGlobal.set Linter, Results
                  else @Messages.set Linter, Results
                Resolve()
              .catch (Error)=>
                if Linter.scope is 'global' then @Linter.MessagesGlobal.delete Linter
                else @Messages.delete Linter
                atom.notifications.addError "#{Error.message}", {detail: Error.stack, dismissable: true}
                Resolve()
            else
              if RetVal instanceof Array
                if Linter.scope is 'global' then @Linter.MessagesGlobal.set Linter, RetVal
                else @Messages.set Linter, RetVal
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
    Utils.values(@Messages).forEach (Entry)->
      ToReturn = ToReturn.concat Entry[1]
    ToReturn

  destroy: ->
    @Emitter.emit 'did-destroy'
    @Subscriptions.dispose()

  onDidUpdate: (Callback) ->
    @Emitter.on 'did-update', Callback

  onDidDestroy: (Callback) ->
    @Emitter.on 'did-destroy', Callback


module.exports = EditorLinter