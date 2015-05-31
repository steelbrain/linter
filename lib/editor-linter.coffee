{CompositeDisposable, Emitter} = require 'atom'

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
      @Linter.Bubble.update newBufferPosition
    )

  lint: (OnChange) ->
    return if @progress OnChange
    return if @Editor isnt @Linter.ActiveEditor
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
    @Linter.Linters.forEach (Linter) =>
      return if OnChange and not Linter.lintOnFly
      return if (not OnChange) and Linter.lintOnFly
      return unless (Scopes.filter (Entry) -> Linter.scopes.indexOf(Entry) isnt -1 ).length
      Promises.push(
        (
          new Promise (Resolve) =>
            RetVal = Linter.lint(@Editor, @Buffer, OnChange)
            if RetVal instanceof Promise
              RetVal.then (Results) =>
                if Results instanceof Array
                  if Linter.scope is 'project' then @Linter.MessagesProject.set Linter, Results
                  else @Messages.set Linter, Results
                Resolve()
              .catch (Error) =>
                if Linter.scope is 'project' then @Linter.MessagesProject.delete Linter
                else @Messages.delete Linter
                atom.notifications.addError "#{Error.message}", {detail: Error.stack, dismissable: true}
                Resolve()
            else
              if RetVal instanceof Array
                if Linter.scope is 'project' then @Linter.MessagesProject.set Linter, RetVal
                else @Messages.set Linter, RetVal
              Resolve()
        ).then =>
          @Emitter.emit 'did-update'
          @Linter.View.render() if @Editor is @Linter.ActiveEditor
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

  destroy: ->
    @Emitter.emit 'did-destroy'
    @Subscriptions.dispose()

  onDidUpdate: (Callback) ->
    @Emitter.on 'did-update', Callback

  onDidDestroy: (Callback) ->
    @Emitter.on 'did-destroy', Callback


module.exports = EditorLinter