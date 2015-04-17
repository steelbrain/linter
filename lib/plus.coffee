

{CompositeDisposable} = require('atom')

class LinterPlus
  Subscriptions: null
  InProgress: false
  Linters: []
  constructor:->
    @Subscriptions = new CompositeDisposable
    @Subscriptions.add atom.workspace.observeTextEditors (editor)=>
      return if @InProgress
      editor.onDidSave(@lint.bind(@))
  lint:->
    @InProgress = true

    ActiveEditor = atom.workspace.getActiveEditor()
    Buffer = ActiveEditor.getBuffer()
    return unless ActiveEditor
    Scopes = ActiveEditor.scopeDescriptorForBufferPosition(ActiveEditor.getCursorBufferPosition()).scopes
    Promises = []
    @Linters.forEach (Linter)->
      Matching = Scopes.filter (Entry)-> Linter.scopes.indexOf(Entry) isnt -1
      return unless Matching.length
      RetVal = Linter.lint(ActiveEditor, Buffer)
      if RetVal instanceof Promise
        Promises.push RetVal
      else if RetVal
        Promises.push RetVal
    Promise.all(Promises).then =>
      @InProgress = false
    , =>
      @InProgress = false
  deactivate:->
    @Subscriptions.dispose()

module.exports = LinterPlus