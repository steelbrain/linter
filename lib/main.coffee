{Disposable} = require('atom')
module.exports =
  instance: null
  config:
    lintOnFly:
      title: 'Lint As You Type'
      description: 'Lint files while typing, without the need to save'
      type: 'boolean'
      default: true
      order: 1
    lintOnFlyInterval:
      title: 'Lint As You Type Interval'
      description: 'Interval at which providers are triggered as you type (in ms)'
      type: 'integer'
      default: 300
      order: 1

    ignoredMessageTypes:
      description: 'Comma separated list of message types to completely ignore'
      type: 'array'
      default: []
      items:
        type: 'string'
      order: 2
    ignoreVCSIgnoredFiles:
      title: 'Do Not Lint Files Ignored by VCS'
      description: 'E.g., ignore files specified in .gitignore'
      type: 'boolean'
      default: true
      order: 2
    ignoreMatchedFiles:
      title: 'Do Not Lint Files that match this Glob'
      type: 'string'
      default: '/**/*.min.{js,css}'
      order: 2

    showErrorInline:
      title: 'Show Inline Error Tooltips'
      type: 'boolean'
      default: true
      order: 3
    inlineTooltipInterval:
      title: 'Inline Tooltip Interval'
      description: 'Interval at which inline tooltip is updated (in ms)'
      type: 'integer'
      default: 60
      order: 3
    gutterEnabled:
      title: 'Highlight Error Lines in Gutter'
      type: 'boolean'
      default: true
      order: 3
    gutterPosition:
      title: 'Position of Gutter Highlights'
      enum: ['Left', 'Right']
      default: 'Right'
      order: 3
      type: 'string'
    underlineIssues:
      title: 'Underline Issues'
      type: 'boolean'
      default: true
      order: 3
    showProviderName:
      title: 'Show Provider Name (When Available)'
      type: 'boolean'
      default: true
      order: 3

    showErrorPanel:
      title: 'Show Error Panel'
      description: 'Show a list of errors at the bottom of the editor'
      type: 'boolean'
      default: true
      order: 4
    errorPanelHeight:
      title: 'Error Panel Height'
      description: 'Height of the error panel (in px)'
      type: 'number'
      default: 150
      order: 4
    alwaysTakeMinimumSpace:
      title: 'Automatically Reduce Error Panel Height'
      description: 'Reduce panel height when it exceeds the height of the error list'
      type: 'boolean'
      default: true
      order: 4

    displayLinterInfo:
      title: 'Display Linter Info in the Status Bar'
      description: 'Whether to show any linter information in the status bar'
      type: 'boolean'
      default: true
      order: 5
    displayLinterStatus:
      title: 'Display Linter Status Info in Status Bar'
      description: 'The `No Issues` or `X Issues` widget'
      type: 'boolean'
      default: true
      order: 5
    showErrorTabLine:
      title: 'Show "Line" Tab in the Status Bar'
      type: 'boolean'
      default: false
      order: 5
    showErrorTabFile:
      title: 'Show "File" Tab in the Status Bar'
      type: 'boolean'
      default: true
      order: 5
    showErrorTabProject:
      title: 'Show "Project" Tab in the Status Bar'
      type: 'boolean'
      default: true
      order: 5
    statusIconScope:
      title: 'Scope of Linter Messages to Show in Status Icon'
      type: 'string'
      enum: ['File', 'Line', 'Project']
      default: 'Project'
      order: 5
    statusIconPosition:
      title: 'Position of Status Icon in the Status Bar'
      enum: ['Left', 'Right']
      type: 'string'
      default: 'Left'
      order: 5

  activate: (@state) ->
    LinterPlus = require('./linter.coffee')
    @instance = new LinterPlus state

  serialize: ->
    @state

  consumeLinter: (linters) ->
    unless linters instanceof Array
      linters = [ linters ]

    for linter in linters
      @instance.addLinter(linter)

    new Disposable =>
      for linter in linters
        @instance.deleteLinter(linter)

  consumeStatusBar: (statusBar) ->
    @instance.views.attachBottom(statusBar)

  provideLinter: ->
    @instance

  deactivate: ->
    @instance?.deactivate()
