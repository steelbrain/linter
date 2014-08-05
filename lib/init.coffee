LinterView = require './linter-view'
StatusBarView = require './statusbar-view'

# Public: linter package initialization, sets up the linter for usages by atom
class LinterInitializer

  # Internal: Configuration Option defaults
  configDefaults:
    lintOnSave: true
    lintOnChange: true
    lintOnEditorFocus: true
    showHighlighting: true
    showGutters: true
    showErrorInStatusBar: true
    lintOnChangeInterval: 1000
    showStatusBarWhenCursorIsInErrorRange: false
    lintDebug: false

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
        linterView.initLinters(@linters)
        linterView.lint()
        @linterViews.push(linterView)

  # Internal: add a linter to a new editor view
  injectLinterViewIntoEditorView: (editorView, statusBarView) ->
    return unless editorView.getPane()?
    return unless editorView.attached
    return if editorView.linterView?

    linterView = new LinterView(editorView, statusBarView, @linters)
    linterView

  # Public: deactivate the plugin and unregister all subscriptions
  deactivate: ->
    @editorViewSubscription.off()
    @statusBarView.remove()
    linterView.remove() for linterView in @linterViews

module.exports = new LinterInitializer()
