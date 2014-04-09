Linter = require './linter'
LinterView = require './linter-view'
App = require './app'

LinterPhpcs = require './linter-phpcs'
LinterPhp = require './linter-php'

module.exports =
  configDefaults:
    lintOnSave: true
    lintOnModified: true

  # Activate the plugin
  activate: ->
    atom.workspaceView.command 'linter:toggle', => @toggle()
    @lintViews = []
    @enable()

    # App = new App

  enable: ->
    @enabled = true

    @linters = [
        LinterPhp
    ]
    # Subscribing to every current and future editor
    @editorViewSubscription = atom.workspaceView.eachEditorView (editorView) =>
      lintView = @injectLintViewIntoEditorView(editorView)
      editorView.editor.on 'grammar-changed', =>
        console.log 'linter: grammar changed'
        lintView.unsetLinters()

        for linter in @initLinters(editorView.editor.getGrammar().scopeName)
          lintView.initLinter(linter)
        lintView.lint()

  injectLintViewIntoEditorView: (editorView) ->
    return unless editorView.getPane()?
    return unless editorView.attached
    return if editorView.lintView?
    console.log @initLinters(editorView.editor.getGrammar().scopeName)
    new LinterView editorView

  initLinters: (grammarName) ->
    linters = []
    for linter in @linters
      sytaxType = {}.toString.call(linter.syntax)
      console.log grammarName, sytaxType, linter.syntax, sytaxType is '[object Array]' && grammarName in linter.syntax or sytaxType is '[object String]' && grammarName is linter.syntax
      if sytaxType is '[object Array]' && grammarName in linter.syntax or sytaxType is '[object String]' && grammarName is linter.syntax
        linters.push(linter)
    linters
