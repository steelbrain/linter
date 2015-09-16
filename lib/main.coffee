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
      title: "Ignored message Types"
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
    underlineIssues:
      title: 'Underline Issues'
      type: 'boolean'
      default: true
      order: 3

    showErrorPanel:
      title: 'Show Error Panel at the Bottom'
      description: 'Show the list of errors in a bottom panel'
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
      title: "Scope of messages to show in status icon"
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
    {deprecate} = require('grim')
    for atomPackage in atom.packages.getLoadedPackages()
      deprecate('AtomLinter legacy API has been removed.
        Please refer to the Linter docs to update and the latest API:
        https://github.com/atom-community/linter/wiki/Migrating-to-the-new-API', {
        packageName: atomPackage.name
      }) if atomPackage.metadata['linter-package']


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
