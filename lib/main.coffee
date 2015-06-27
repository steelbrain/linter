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
      title: 'Show line tab in error panel'
      type: 'boolean'
      default: false
    showErrorTabFile:
      title: 'Show file tab in error panel'
      type: 'boolean'
      default: true
    showErrorTabProject:
      title: 'Show project tab in error panel'
      type: 'boolean'
      default: true
    defaultErrorTab:
      type: 'string'
      default: 'File'
      enum: ['Line', 'File', 'Project']
    showErrorInline:
      title: 'Show Inline Tooltips'
      descriptions: 'Show inline tooltips for errors'
      type: 'boolean'
      default: true
    underlineIssues:
      title: 'Underline Issues'
      type: 'boolean'
      default: true
    statusIconPosition:
      title: 'Position of Status Icon on Bottom Bar'
      description: 'Requires a reload/restart to update'
      enum: ['Left', 'Right']
      type: 'string'
      default: 'Left'

  activate: ->
    LinterPlus = require('./linter-plus.coffee')
    @instance = new LinterPlus()

    legacy = require('./legacy.coffee')
    for atomPackage in atom.packages.getLoadedPackages()
      if atomPackage.metadata['linter-package'] is true
        implementation = atomPackage.metadata['linter-implementation'] ? atomPackage.name
        linter = legacy(require("#{atomPackage.path}/lib/#{implementation}"))
        @consumeLinter(linter)

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
