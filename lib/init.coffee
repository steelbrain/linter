Linter = require './linter'
LinterView = require './linter-view'

module.exports =
  configDefaults:
    lintOnSave: true
    lintOnModified: true

  # Activate the plugin
  activate: ->
    atom.workspaceView.command 'linter:toggle', => @toggle()
    @linterViews = []
    @linters = []
    for atomPackage in atom.packages.getAvailablePackageNames()
      if atomPackage.match(/^linter-/)
        if atom.packages.getLoadedPackage(atomPackage).metadata['linter-package'] is true
          @linters.push(require "#{atom.packages.getLoadedPackage(atomPackage).path}/lib/#{atomPackage}")
    @enable()

    # App = new App

  enable: ->
    @enabled = true
    # Subscribing to every current and future editor
    @editorViewSubscription = atom.workspaceView.eachEditorView (editorView) =>
      linterView = @injectLinterViewIntoEditorView(editorView)
      editorView.editor.on 'grammar-changed', =>
        console.log 'linter: grammar changed'
        linterView.unsetLinters()

        for linter in @initLinters(editorView.editor.getGrammar().scopeName)
          linterView.initLinter(linter)
        linterView.lint()

  injectLinterViewIntoEditorView: (editorView) ->
    return unless editorView.getPane()?
    return unless editorView.attached
    return if editorView.linterView?
    @initLinters(editorView.editor.getGrammar().scopeName)
    new LinterView editorView

  initLinters: (grammarName) ->
    linters = []
    for linter in @linters
      sytaxType = {}.toString.call(linter.syntax)
      if sytaxType is '[object Array]' && grammarName in linter.syntax or sytaxType is '[object String]' && grammarName is linter.syntax
        linters.push(linter)
    linters
