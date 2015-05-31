{CompositeDisposable, Emitter} = require 'atom'

class EditorLinter
  constructor: (@linter, @editor) ->
    @inProgress = false
    @inProgressFly = false
    @messages = new Map

    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @buffer = Editor.getBuffer()

    @subscriptions.add(@editor.onDidSave @lint.bind(@, false))
    @subscriptions.add(@editor.onDidStopChanging @lint.bind(@, true)) if @linter.lintOnFly
    @subscriptions.add(@editor.onDidChangeCursorPosition ({newBufferPosition}) =>
      @linter.bubble.update newBufferPosition
    )

  lint: (onChange) ->
    return if @progress onChange
    return if @editor isnt @linter.activeEditor
    @progress onChange, true
    @lint true unless onChange

    scopes = @editor.scopeDescriptorForBufferPosition(@editor.getCursorBufferPosition()).scopes
    promises = @lintResults onChange, scopes
    promise.all(promises).then =>
      @progress onChange, false
    .catch ->
      console.error arguments[0].stack
      @progress onChange, false
  lintResults: (onChange, scopes) ->
    promises = []
    @linter.linters.forEach (linter) =>
      return if onChange and not linter.lintOnFly
      return if (not onChange) and linter.lintOnFly
      return unless (scopes.filter (entry) -> linter.scopes.indexOf(entry) isnt -1 ).length
      promises.push(
        (
          new Promise (resolve) =>
            retVal = linter.lint(@editor, @buffer)
            if retVal instanceof promise
              retVal.then (results) =>
                if results instanceof Array
                  if linter.scope is 'project' then @linter.messagesProject.set linter, results
                  else @messages.set linter, results
                resolve()
              .catch (error) =>
                if linter.scope is 'project' then @linter.messagesProject.delete linter
                else @messages.delete linter
                atom.notifications.addError "#{error.message}", {detail: error.stack, dismissable: true}
                resolve()
            else
              if retVal instanceof Array
                if linter.scope is 'project' then @linter.messagesProject.set linter, retVal
                else @messages.set linter, retVal
              resolve()
        ).then =>
          @emitter.emit 'did-update'
          @linter.view.render() if @editor is @linter.activeEditor
      )
    promises

  progress: (onChange, newValue) ->
    if typeof newValue is 'undefined'
      if onChange
        return @inProgressFly
      else
        return @inProgress
    else
      if onChange
        @inProgressFly = newValue
      else
        @inProgress = newValue

  destroy: ->
    @emitter.emit 'did-destroy'
    @subscriptions.dispose()

  onDidUpdate: (callback) ->
    @emitter.on 'did-update', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback


module.exports = EditorLinter
