{CompositeDisposable, Emitter} = require 'atom'

class EditorLinter
  constructor: (@Linter, @Editor) ->
    @Emitter = new Emitter
    @Subscriptions = new CompositeDisposable
    @Buffer = Editor.getBuffer()

    @Subscriptions.add @Editor.onDidSave @lint.bind(@, false)
    @Subscriptions.add @Editor.onDidStopChanging @lint.bind(@, true)

  lint: (OnChange)->
    console.log "Lint"
  destroy:->
    @Emitter.emit 'did-destroy'
    @Subscriptions.dispose()

  onDidUpdate:(Callback)->
    @Emitter.on 'did-update', Callback

  onDidDestroy:(Callback)->
    @Emitter.on 'did-destroy', Callback


module.exports = EditorLinter