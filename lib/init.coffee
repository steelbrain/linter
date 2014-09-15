LinterView = require './linter-view'
StatusBarView = require './statusbar-view'
InlineView = require './inline-view'
# Public: linter package initialization, sets up the linter for usages by atom
class LinterInitializer

  # Internal: Configuration Option defaults
  configDefaults:
    lintOnSave: true
    lintOnChange: true
    lintOnEditorFocus: true
    showAllErrorsInStatusBar: false
    showHighlighting: true
    showGutters: true
    showErrorInStatusBar: true
    showErrorInline: false
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
    @inlineView = new InlineView()

    # Subscribing to every current and future editor
    @editorViewSubscription = atom.workspaceView.eachEditorView (editorView) =>
      linterView = @injectLinterViewIntoEditorView(editorView, @statusBarView, @inlineView)
      editorView.editor.on 'grammar-changed', =>
        linterView.initLinters(@linters)
        linterView.lint()
        @linterViews.push(linterView)

  # Internal: add a linter to a new editor view
  injectLinterViewIntoEditorView: (editorView, statusBarView, inlineView) ->
    return unless editorView.getPane()?
    return unless editorView.attached
    return if editorView.linterView?

    linterView = new LinterView(editorView, statusBarView, inlineView, @linters)
    linterView

  # Public: deactivate the plugin and unregister all subscriptions
  deactivate: ->
    @editorViewSubscription.off()
    linterView.remove() for linterView in @linterViews
    @inlineView.remove()
    @statusBarView.remove()

module.exports = new LinterInitializer()
