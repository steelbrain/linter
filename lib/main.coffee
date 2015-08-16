{Disposable} = require('atom')
module.exports =
  instance: null
  config:
    lintOnFly:
      title: 'Lint on fly'
      description: 'Lint files while typing, without the need to save them'
      type: 'boolean'
      default: true
    showErrorPanel:
      title: 'Show Error Panel at the bottom'
      type: 'boolean'
      default: true
    showErrorTabLine:
      title: 'Show Line tab in Bottom Panel'
      type: 'boolean'
      default: false
    showErrorTabFile:
      title: 'Show File tab in Bottom Panel'
      type: 'boolean'
      default: true
    showErrorTabProject:
      title: 'Show Project tab in Bottom Panel'
      type: 'boolean'
      default: true
    showErrorInline:
      title: 'Show Inline Tooltips'
      descriptions: 'Show inline tooltips for errors'
      type: 'boolean'
      default: true
    underlineIssues:
      title: 'Underline Issues'
      type: 'boolean'
      default: true
    ignoredMessageTypes:
      title: "Ignored message Types"
      type: 'array'
      default: []
      items:
        type: 'string'
    statusIconScope:
      title: "Scope of messages to show in status icon"
      type: 'string'
      enum: ['File', 'Line', 'Project']
      default: 'Project'
    statusIconPosition:
      title: 'Position of Status Icon on Bottom Bar'
      enum: ['Left', 'Right']
      type: 'string'
      default: 'Left'

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
