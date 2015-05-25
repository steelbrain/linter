

Path = require 'path'
{CompositeDisposable} = require('atom')

class PlusTrace
  constructor:(@Message, @File, @Position)->
class PlusMessage then constructor:(@Message, @File, @Position, @Trace)->
class PlusError extends PlusMessage
class PlusWarning extends PlusMessage

class LinterPlus
  Subscriptions: null
  SubLintOnFly: null
  InProgress: false
  InProgressFly: false
  LintOnFly: true
  View: null
  ViewPanel: null
  Messages:[]
  MessagesRegular:[]
  MessagesFly:[]
  Linters: []
  constructor:->
    @View = new (require './view')(this)
    @ViewPanel = atom.workspace.addBottomPanel item: @View.root, visible: false

    @Subscriptions = new CompositeDisposable
    @SubLintOnFly = new CompositeDisposable
    @Subscriptions.add atom.workspace.onDidChangeActivePaneItem =>
      return unless atom.workspace.getActiveTextEditor()
      @lint()
    @Subscriptions.add atom.workspace.observeTextEditors (editor)=>
      return unless editor.getPath()
      editor.onDidSave(@lint.bind(@, false))
      @Subscriptions.add editor.onDidChangeCursorPosition ({newBufferPosition})=>
        @View.updateBubble(newBufferPosition)
      return unless @LintOnFly
      @SubLintOnFly.add editor.onDidStopChanging @lint.bind(@, true)
  lint:(onChange)->
    if onChange
      return if @InProgressFly
      @InProgressFly = true
    else
      return if @InProgress
      @InProgress = true
    onChange = Boolean onChange
    @lint(true) unless onChange

    ActiveEditor = atom.workspace.getActiveTextEditor()
    Buffer = ActiveEditor.getBuffer()
    return unless ActiveEditor
    Scopes = ActiveEditor.scopeDescriptorForBufferPosition(ActiveEditor.getCursorBufferPosition()).scopes
    Promises = []
    @Linters.forEach (Linter)->
      return if (onChange and not Linter.lintOnFly) or onChange
      Matching = Scopes.filter (Entry)-> Linter.scopes.indexOf(Entry) isnt -1
      return unless Matching.length
      RetVal = Linter.lint(ActiveEditor, Buffer, {Error: PlusError, Warning: PlusWarning, Trace: PlusTrace}, onChange)
      if RetVal instanceof Promise
        Promises.push RetVal
      else if RetVal
        Promises.push RetVal
    Promise.all(Promises).then (Results)=>
      if onChange
        @InProgressFly = false
      else
        @InProgress = false
      Messages = []
      for Result in Results
        continue if (not Result) or (typeof Result) isnt 'object'
        if Result instanceof Array
          Messages = Messages.concat(Result)
        else
          Messages.push Result
      if onChange
        @MessagesFly = Messages
      else
        @MessagesRegular = Messages
      @Messages = @MessagesFly.concat(@MessagesRegular)
      @render()
    , =>
      console.error arguments
      if onChange
        @InProgressFly = false
      else
        @InProgress = false
  render:->
    if not @Messages.length
      @ViewPanel.hide() if @ViewPanel.isVisible()
      @View.remove()
      return ;
    @View.update()
    @ViewPanel.show() if not @ViewPanel.isVisible()
  deactivate:->
    @ViewPanel.destroy()
    @View.remove()
    @SubLintOnFly.dispose()
    @Subscriptions.dispose()

module.exports = LinterPlus