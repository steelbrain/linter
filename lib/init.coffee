Linter = require './linter'
LinterView = require './linter-view'
StatusBarView = require './statusbar-view'

# Public: linter package initialization, sets up the linter for ussages by atom
class LinterInitializer

  # Internal: Configuration Option defaults
  configDefaults:
    lintOnSave: true
    lintOnModified: true
    showHightlighting: true
    showGutters: true
    showMessagesAroundCursor: true
    lintOnModifyDebounceInterval: 1000
    showStatusBarWhenCursorIsInErrorRange: false

  # Public: Activate the plugin setting up StatusBarView and dicovering linters
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
        @linterViews.push(linterView)

  # Internal: add a linter to a new editor view
  injectLinterViewIntoEditorView: (editorView, statusBarView) ->
    return unless editorView.getPane()?
    return unless editorView.attached
    return if editorView.linterView?
    console.log "editorView.editor.getGrammar().scopeName" +
      editorView.editor.getGrammar().scopeName
    linterView = new LinterView(editorView, statusBarView, @linters)
    linterView

  # Public: deactivate the plugin and unregister all subscriptions
  deactivate: ->
    @editorViewSubscription.off()
    @statusBarView.remove()
    linterView.remove() for linterView in @linterViews

module.exports = new LinterInitializer()
