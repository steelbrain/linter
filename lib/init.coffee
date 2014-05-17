Linter = require './linter'
LinterView = require './linter-view'
StatusBarView = require './statusbar-view'

module.exports =
  configDefaults:
    lintOnSave: true
    lintOnModified: true

  # Activate the plugin
  activate: ->
    @linterViews = []

    @linters = []
    for atomPackage in atom.packages.getLoadedPackages()
      if atomPackage.metadata['linter-package'] is true
        implemention = atomPackage.metadata['linter-implementation'] ? atomPackage.name
        @linters.push(require "#{atomPackage.path}/lib/#{implemention}")

    @enabled = true
    @statusBarView = new StatusBarView()

    # Subscribing to every current and future editor
    @editorViewSubscription = atom.workspaceView.eachEditorView (editorView) =>
      linterView = @injectLinterViewIntoEditorView(editorView, @statusBarView)
      editorView.editor.on 'grammar-changed', =>
        console.log 'linter: grammar changed'
        linterView.initLinters(@linters)
        linterView.lint()

  injectLinterViewIntoEditorView: (editorView, statusBarView) ->
    return unless editorView.getPane()?
    return unless editorView.attached
    return if editorView.linterView?
    console.log "editorView.editor.getGrammar().scopeName"+editorView.editor.getGrammar().scopeName
    linterView = new LinterView editorView, statusBarView, @linters
    linterView
