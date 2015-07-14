{TextEditor, Emitter, CompositeDisposable} = require('atom')

class EditorLinter
  constructor: (@editor) ->
    throw new Error("Given editor isn't really an editor") unless @editor instanceof TextEditor
    @status = true # Overall linting status
    @emitter = new Emitter
    @subscriptions = new CompositeDisposable
    @subscriptions.add @editor.onDidDestroy =>
      @emitter.emit 'did-destroy'

    @subscriptions.add @editor.onDidSave => @emitter.emit('should-lint', false)
    # The onDidStopChanging callbacks are invoked immediately, and we want to avoid it
    setImmediate =>
      @subscriptions.add @editor.onDidStopChanging => setImmediate => @emitter.emit('should-lint', true)
      cursorImmediate = null
      @subscriptions.add @editor.onDidChangeCursorPosition ({oldBufferPosition, newBufferPosition}) =>
        if newBufferPosition.row isnt oldBufferPosition.row
          clearImmediate(cursorImmediate)
          cursorImmediate = setImmediate => @emitter.emit('should-update-line-messages')
        @emitter.emit('should-update-bubble')

  lint: ->
    # Only for legacy external or maybe internal APIs
    @emitter.emit('should-lint')

  onShouldUpdateBubble: (callback) ->
    return @emitter.on('should-update-bubble', callback)

  onShouldUpdateLineMessages: (callback) ->
    return @emitter.on('should-update-line-messages', callback)

  onShouldLint: (callback) ->
    return @emitter.on('should-lint', callback)

  onDidDestroy: (callback) ->
    return @emitter.on('did-destroy', callback)

  deactivate: ->
    @emitter.dispose()
    @subscriptions.dispose()

module.exports = EditorLinter
