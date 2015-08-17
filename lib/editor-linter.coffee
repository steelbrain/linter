{TextEditor, Emitter, CompositeDisposable} = require('atom')

class EditorLinter
  constructor: (@editor) ->
    throw new Error("Given editor isn't really an editor") unless @editor instanceof TextEditor
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @subscriptions.add @emitter
    @subscriptions.add @editor.onDidDestroy =>
      @emitter.emit 'did-destroy'

    @subscriptions.add @editor.onDidSave => @emitter.emit('should-lint', false)
    @subscriptions.add @editor.onDidChangeCursorPosition ({oldBufferPosition, newBufferPosition}) =>
      if newBufferPosition.row isnt oldBufferPosition.row
        @emitter.emit('should-update-line-messages')
      @emitter.emit('should-update-bubble')
    # The onDidStopChanging callbacks are invoked immediately on creation, We are just
    # gonna wait until a bit to get real events
    setImmediate =>
      @subscriptions.add @editor.onDidStopChanging => @lint(true)

  lint: (onChange = false) ->
    @emitter.emit('should-lint', onChange)

  onShouldUpdateBubble: (callback) ->
    return @emitter.on('should-update-bubble', callback)

  onShouldUpdateLineMessages: (callback) ->
    return @emitter.on('should-update-line-messages', callback)

  onShouldLint: (callback) ->
    return @emitter.on('should-lint', callback)

  onDidDestroy: (callback) ->
    return @emitter.on('did-destroy', callback)

  destroy: ->
    @emitter.emit('did-destroy')
    @dispose()

  dispose: ->
    @subscriptions.dispose()

module.exports = EditorLinter
