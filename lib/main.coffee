{Disposable} = require('atom')
module.exports =
  instance: null
  config:
    lintOnFly:
      title: 'Lint on fly'
      description: 'Lint files while typing, without the need to save them'
      type: 'boolean'
      default: true
      order: 1

    ignoredMessageTypes:
      title: 'Ignored message Types'
      type: 'array'
      default: []
      items:
        type: 'string'
      order: 2

    showErrorInline:
      title: 'Show Inline Tooltips'
      description: 'Show inline tooltips for errors'
      type: 'boolean'
      default: true
      order: 3
    gutterEnabled:
      title: 'Highlight error lines in gutter'
      type: 'boolean'
      default: true
      order: 3
    gutterPosition:
      title: 'Position of gutter highlights'
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
      title: 'Show Provider Name (when available)'
      type: 'boolean'
      default: true
      order: 3

    showErrorPanel:
      title: 'Show Error Panel at the Bottom'
      description: 'Show the list of errors in a bottom panel'
      type: 'boolean'
      default: true
      order: 4
    errorPanelHeight:
      title: 'Error Panel Height'
      description: 'The error panel height in pixels'
      type: 'number'
      default: 150
      order: 4
    alwaysTakeMinimumSpace:
      title: 'Always Take Minimum Space'
      description: 'Resize the error panel smaller than the height where possible'
      type: 'boolean'
      default: true
      order: 4

    displayLinterInfo:
      title: 'Display Linter Info in Status Bar'
      description: 'Whether to show any linter information in the status bar'
      type: 'boolean'
      default: true
      order: 5
    showErrorTabLine:
      title: 'Show Line tab in Status Bar'
      type: 'boolean'
      default: false
      order: 5
    showErrorTabFile:
      title: 'Show File tab in Status Bar'
      type: 'boolean'
      default: true
      order: 5
    showErrorTabProject:
      title: 'Show Project tab in Status Bar'
      type: 'boolean'
      default: true
      order: 5
    statusIconScope:
      title: 'Scope of messages to show in status icon'
      type: 'string'
      enum: ['File', 'Line', 'Project']
      default: 'Project'
      order: 5
    statusIconPosition:
      title: 'Position of Status Icon in Status Bar'
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
