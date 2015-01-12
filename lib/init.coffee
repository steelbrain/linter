_ = require 'lodash'
{CompositeDisposable} = require 'event-kit'

LinterView = require './linter-view'
StatusBarView = require './statusbar-view'
StatusBarSummaryView = require './statusbar-summary-view'
InlineView = require './inline-view'


# Public: linter package initialization, sets up the linter for usages by atom
class LinterInitializer

  # Internal: Configuration Option defaults
  config:
    lintOnSave:
      type: 'boolean'
      default: true
    lintOnChange:
      type: 'boolean'
      default: true
    lintOnEditorFocus:
      type: 'boolean'
      default: true
    showHighlighting:
      type: 'boolean'
      default: true
    showGutters:
      type: 'boolean'
      default: true
    lintOnChangeInterval:
      type: 'integer'
      default: 1000
    lintDebug:
      type: 'boolean'
      default: false
    showErrorInline:
      type: 'boolean'
      default: false
    statusBar:
      type: 'string'
      default: 'Show error of the selected line'
      enum: ['None', 'Show all errors', 'Show error of the selected line', 'Show error if the cursor is in range']
    executionTimeout:
      type: 'integer'
      default: 5000
      description: 'Linter executables are killed after this timeout. Set to 0 to disable.'

  # Internal: Prevent old deprecated config to be visible in the package settings
  setDefaultOldConfig: ->
    # Keep the old config settings
    if (atom.config.get('linter.showErrorInStatusBar') == false)
      atom.config.set('linter.statusBar', 'None')
    else if (atom.config.get('linter.showAllErrorsInStatusBar'))
      atom.config.set('linter.statusBar', 'Show all errors')
    else if (atom.config.get('linter.showStatusBarWhenCursorIsInErrorRange'))
      atom.config.set('linter.statusBar', 'Show error if the cursor is in range')

    atom.config.restoreDefault('linter.showAllErrorsInStatusBar')
    atom.config.restoreDefault('linter.showErrorInStatusBar')
    atom.config.restoreDefault('linter.showStatusBarWhenCursorIsInErrorRange')

  # Public: Activate the plugin setting up StatusBarView and dicovering linters
  activate: ->
    @setDefaultOldConfig()
    @linterViews = []
    @linters = []
    @subscriptions = new CompositeDisposable

    for atomPackage in atom.packages.getLoadedPackages()
      if atomPackage.metadata['linter-package'] is true
        implemention = atomPackage.metadata['linter-implementation'] ? atomPackage.name
        @linters.push(require "#{atomPackage.path}/lib/#{implemention}")

    @enabled = true
    @statusBarView = new StatusBarView()
    @statusBarSummaryView = new StatusBarSummaryView()
    @inlineView = new InlineView()

    # Subscribing to every current and future editor
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      return if editor.linterView?

      linterView = new LinterView(editor, @statusBarView, @statusBarSummaryView,
                                  @inlineView, @linters)
      @linterViews.push linterView
      @subscriptions.add linterView.onDidDestroy =>
        @linterViews = _.without @linterViews, linterView

  # Public: deactivate the plugin and unregister all subscriptions
  deactivate: ->
    @subscriptions.dispose()
    linterView.remove() for linterView in @linterViews
    @inlineView.remove()
    @statusBarView.remove()
    @statusBarSummaryView.remove()
    l.destroy() for l in @linters

module.exports = new LinterInitializer()
