

{CompositeDisposable} = require('atom')
Messages = require './Messages'

class LinterPlus
  Subscriptions: null
  InProgress: false
  Messages:[]
  Linters: []
  constructor:->
    @Subscriptions = new CompositeDisposable
    @Subscriptions.add atom.workspace.observeTextEditors (editor)=>
      return if @InProgress
      return unless editor.getPath()
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
      RetVal = Linter.lint(ActiveEditor, Buffer, {Error: Messages.Error, Warning: Messages.Warning})
      if RetVal instanceof Promise
        Promises.push RetVal
      else if RetVal
        Promises.push RetVal
    Promise.all(Promises).then (Results)=>
      @InProgress = false
      Messages = []
      for Result in Results
        return if (not Result) or (typeof Result) isnt 'object'
        if Result instanceof Array
          Messages = Messages.concat(Result)
        else
          Messages.push Result
      @Messages = Messages
      @render()
    , =>
      @InProgress = false
  render:->

  deactivate:->
    @Subscriptions.dispose()

module.exports = LinterPlus