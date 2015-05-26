Path = require 'path'
{CompositeDisposable} = require 'atom'

class LinterTrace
  constructor: (@Message, @File, @Position) ->

class LinterMessage then constructor: (@Message, @File, @Position, @Trace) ->

class LinterError extends LinterMessage

class LinterWarning extends LinterMessage

class Linter

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

  constructor: ->
    @View = new (require './view')(this)
    @ViewPanel = atom.workspace.addBottomPanel item: @View.root, visible: false

    @Subscriptions = new CompositeDisposable
    @SubLintOnFly = new CompositeDisposable

    @Subscriptions.add atom.workspace.onDidChangeActivePaneItem =>
      return unless atom.workspace.getActiveTextEditor()
      @lint()

    @Subscriptions.add atom.workspace.observeTextEditors (editor) =>
      return unless editor.getPath()
      editor.onDidSave(@lint.bind(@, false))
      @Subscriptions.add editor.onDidChangeCursorPosition ({newBufferPosition}) =>
        @View.updateBubble(newBufferPosition)
      return unless @LintOnFly
      @SubLintOnFly.add editor.onDidStopChanging @lint.bind(@, true)

  lint: (onChange) ->
    onChange = Boolean onChange
    return if @progress onChange
    # We need to consume both onFly and Regular linters on save
    @lint true unless onChange

    ActiveEditor = atom.workspace.getActiveTextEditor()
    Buffer = ActiveEditor.getBuffer()
    return unless ActiveEditor

    Scopes = ActiveEditor.scopeDescriptorForBufferPosition(ActiveEditor.getCursorBufferPosition()).scopes
    Promises = []

    @Linters.forEach (Linter) ->
      return if (onChange and not Linter.lintOnFly) or onChange
      Matching = Scopes.filter (Entry) -> Linter.scopes.indexOf(Entry) isnt -1
      return unless Matching.length
      Promises.push Linter.lint(
        ActiveEditor, Buffer,
        {
          Error: LinterError,
          Warning: LinterWarning,
          Trace: LinterTrace
        },
        onChange
      )

    Promise.all(Promises).then (Results) =>
      @progress onChange, false
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
      @progress onChange, false

  render: ->
    if not @Messages.length
      @ViewPanel.hide() if @ViewPanel.isVisible()
      @View.remove()
      return
    @View.update()
    @ViewPanel.show() if not @ViewPanel.isVisible()

  deactivate: ->
    @ViewPanel.destroy()
    @View.remove()
    @SubLintOnFly.dispose()
    @Subscriptions.dispose()

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

module.exports = Linter
